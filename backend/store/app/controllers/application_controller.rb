class Appointment < ApplicationRecord
  belongs_to :patient
  belongs_to :provider
  belongs_to :appointment_type
  has_many :appointment_slots
  has_one :insurance_verification

  include AASM # State machine for appointment lifecycle

  aasm column: :status do
      state :requested, initial: true
      state :confirmed, :completed, :cancelled, :no_show

      event :confirm do
        transitions from: :requested, to: :confirmed
        after do
          AppointmentConfirmationJob.perform_later(self)
        end
      end
    end
  end

  class SchedulingEngine
    # Complex schedulging algorithm
    def find_optimal_slots(patient:, provider:, preferences:)
      # Showcase algorithms, caching, performnance optimizations
    end
  end 