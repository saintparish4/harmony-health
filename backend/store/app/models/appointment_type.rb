class AppointmentType < ApplicationRecord
    has_many :appointments, dependent: :destroy
  
    validates :name, presence: true, uniqueness: true
    validates :duration_minutes, presence: true, inclusion: { in: 15..480 }
    validates :color, format: { with: /\A#[0-9A-F]{6}\z/i }
  
    scope :telemedicine_eligible, -> { where(telemedicine_eligible: true) }
    scope :requires_prep, -> { where(requires_preparation: true) }
  
    def self.common_types
      [
        { name: 'Initial Consultation', duration_minutes: 60, requires_preparation: true },
        { name: 'Follow-up Visit', duration_minutes: 30 },
        { name: 'Annual Physical', duration_minutes: 45, requires_preparation: true },
        { name: 'Telehealth Consultation', duration_minutes: 30, telemedicine_eligible: true },
        { name: 'Procedure Consultation', duration_minutes: 90, requires_preparation: true }
      ]
    end
  end