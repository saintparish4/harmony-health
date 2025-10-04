class Waitlist < ApplicationRecord
    belongs_to :patient
    belongs_to :provider
    belongs_to :appointment_type
  
    # Scopes
    scope :active, -> { where(status: 'active') }
    scope :by_priority, -> { order(priority: :desc, created_at: :asc) }
    scope :for_time_slot, ->(date, time_of_day) {
      where('preferred_date_start <= ? AND preferred_date_end >= ?', date, date)
        .where("'#{time_of_day}' = ANY(preferred_time_of_day)")
    }
  
    # State machine
    enum status: {
      active: 'active',
      notified: 'notified',
      claimed: 'claimed',
      expired: 'expired',
      cancelled: 'cancelled'
    }
  
    # Validations
    validates :preferred_date_start, :preferred_date_end, presence: true
    validates :preferred_time_of_day, presence: true
    validate :end_date_after_start_date
  
    # Calculate priority based on multiple factors
    def calculate_priority!
      score = 0
      
      # Urgency: how long they've been waiting
      days_waiting = (Time.current - created_at) / 1.day
      score += (days_waiting * 2).to_i
      
      # Previous cancellations (reliability)
      score += patient.appointments.completed.count * 5
      
      # No-show penalty
      score -= patient.appointments.no_show.count * 10
      
      # Manual priority boost from provider/admin
      score += (metadata['manual_priority'] || 0)
      
      update(priority: score)
    end
  
    private
  
    def end_date_after_start_date
      return if preferred_date_end.blank? || preferred_date_start.blank?
  
      if preferred_date_end < preferred_date_start
        errors.add(:preferred_date_end, 'must be after start date')
      end
    end
  end