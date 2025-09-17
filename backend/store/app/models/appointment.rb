class Appointment < ApplicationRecord
    include AASM
  
    belongs_to :patient
    belongs_to :provider
    belongs_to :appointment_type
  
    # Encryptions for HIPAA compliance
    encrypts :reason_for_visit, :notes, :provider_notes
  
    # Validations
    validates :scheduled_at, :ends_at, presence: true
    validates :confirmation_number, uniqueness: true, allow_nil: true
    validate :appointment_in_future
    validate :provider_availability
    validate :patient_no_conflicts
    validate :ends_after_starts
  
    # Callbacks
    before_create :generate_confirmation_number
    before_create :calculate_end_time
    after_save :notify_stakeholders, if: :saved_change_to_status?
    after_update :broadcast_update
    after_create :broadcast_creation
  
    # State machine
    aasm column: :status do
      state :requested, initial: true
      state :confirmed
      state :completed
      state :cancelled
      state :no_show
  
      event :confirm do
        transitions from: :requested, to: :confirmed
        after do
          update!(confirmed_at: Time.current)
          AppointmentConfirmationJob.perform_later(self)
        end
      end
  
      event :complete do
        transitions from: :confirmed, to: :completed
        after do
          update!(completed_at: Time.current)
        end
      end
  
      event :cancel do
        transitions from: [:requested, :confirmed], to: :cancelled
        after do
          update!(cancelled_at: Time.current)
          AppointmentCancellationJob.perform_later(self)
        end
      end
  
      event :mark_no_show do
        transitions from: :confirmed, to: :no_show
      end
    end
  
    # Scopes
    scope :upcoming, -> { where('scheduled_at > ?', Time.current) }
    scope :past, -> { where('scheduled_at < ?', Time.current) }
    scope :today, -> { where(scheduled_at: Date.current.all_day) }
    scope :this_week, -> { where(scheduled_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  
    # Instance methods
    def duration_minutes
      return appointment_type.duration_minutes if ends_at.blank? || scheduled_at.blank?
      ((ends_at - scheduled_at) / 60).to_i
    end
  
    def can_be_cancelled?
      %w[requested confirmed].include?(status) && scheduled_at > 24.hours.from_now
    end
  
    def can_be_rescheduled?
      can_be_cancelled?
    end
  
    def is_upcoming?
      scheduled_at > Time.current
    end
  
    def requires_reminder?
      confirmed? && scheduled_at > Time.current && !reminder_sent['24_hours']
    end
  
    private
  
    def appointment_in_future
      return unless scheduled_at.present?
      
      if scheduled_at <= Time.current
        errors.add(:scheduled_at, 'must be in the future')
      end
    end
  
    def provider_availability
      return unless provider.present? && scheduled_at.present?
      
      # Check if provider has schedule for this date
      schedule = provider.schedule_for_date(scheduled_at.to_date)
      unless schedule&.is_available?
        errors.add(:provider, 'is not available on this date')
        return
      end
  
      # Check for conflicts with existing appointments
      conflicts = provider.appointments
                         .where.not(id: id)
                         .where(status: ['requested', 'confirmed'])
                         .where('scheduled_at < ? AND ends_at > ?', ends_at, scheduled_at)
      
      if conflicts.exists?
        errors.add(:scheduled_at, 'conflicts with existing appointment')
      end
    end
  
    def patient_no_conflicts
      return unless patient.present? && scheduled_at.present?
      
      conflicts = patient.appointments
                        .where.not(id: id)
                        .where(status: ['requested', 'confirmed'])
                        .where('scheduled_at < ? AND ends_at > ?', ends_at, scheduled_at)
      
      if conflicts.exists?
        errors.add(:patient, 'already has an appointment at this time')
      end
    end
  
    def ends_after_starts
      return unless scheduled_at.present? && ends_at.present?
      
      if ends_at <= scheduled_at
        errors.add(:ends_at, 'must be after start time')
      end
    end
  
    def generate_confirmation_number
      self.confirmation_number = SecureRandom.alphanumeric(8).upcase
    end
  
    def calculate_end_time
      return unless scheduled_at.present? && appointment_type.present?
      
      self.ends_at = scheduled_at + appointment_type.duration_minutes.minutes
    end
  
    def notify_stakeholders
      case status
      when 'confirmed'
        PatientNotificationJob.perform_later(patient_id, 'appointment_confirmed', id)
        ProviderNotificationJob.perform_later(provider_id, 'appointment_confirmed', id)
      when 'cancelled'
        PatientNotificationJob.perform_later(patient_id, 'appointment_cancelled', id)
        ProviderNotificationJob.perform_later(provider_id, 'appointment_cancelled', id)
      end
    end

    def broadcast_update
      # Notify patient
      AppointmentsChannel.broadcast_to(
        patient,
        {
          type: 'appointment_updated',
          appointment: AppointmentSerializer.new(self).serializable_hash
        }
      )

      # Notify provider
      AppointmentsChannel.broadcast_to(
        provider,
        {
          type: 'appointment_updated', 
          appointment: AppointmentSerializer.new(self).serializable_hash
        }
      )

      # Broadcast availability change
      AvailabilityChannel.broadcast_to(
        provider,
        {
          type: 'availability_changed',
          date: scheduled_at.to_date.iso8601
        }
      )
    end

    def broadcast_creation
      # Similar to broadcast_update but for new appointments
      broadcast_update
    end
  end