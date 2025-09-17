class PhiAccessLog < ApplicationRecord
    belongs_to :user
    belongs_to :patient
    
    validates :action, :timestamp, presence: true
    
    scope :recent, -> { order(timestamp: :desc) }
    scope :by_patient, ->(patient) { where(patient: patient) }
  end