class Provider < ApplicationRecord
  belongs_to :user
  has_many :appointments, dependent: :destroy
  has_many :provider_schedules, dependent: :destroy
  has_many :patients, -> { distinct }, through: :appointments

  # Validations
  validates :npi_number, presence: true, uniqueness: true, length: { is: 10 }
  validates :license_number, :license_state, presence: true
  validates :specialties, presence: true
  validates :rating, inclusion: { in: 0.0..5.0 }
  validate :npi_number_format

  # Callbacks
  before_save :geocode_practice_address, if: :practice_address_changed?

  # Scopes
  scope :by_specialty, ->(specialty) { where("specialties @> ?", [specialty].to_json) }
  scope :accepting_patients, -> { where(accepting_new_patients: true) }
  scope :by_insurance, ->(insurance) { where("accepted_insurances @> ?", [insurance].to_json) }
  scope :by_location, ->(lat, lng, radius_km) {
    where("ST_DWithin(practice_location, ST_MakePoint(?, ?), ?)", lng, lat, radius_km * 1000)
  }
  scope :by_rating, ->(min_rating) { where('rating >= ?', min_rating) }

  # Instance methods
  def available_on?(date)
    provider_schedules.exists?(date: date, is_available: true)
  end

  def schedule_for_date(date)
    provider_schedules.find_by(date: date)
  end

  def upcoming_appointments
    appointments.where('scheduled_at > ?', Time.current)
                .where(status: ['confirmed', 'requested'])
                .order(:scheduled_at)
  end

  def availability_today
    schedule_for_date(Date.current)
  end

  def accepts_insurance?(insurance_name)
    accepted_insurances.include?(insurance_name)
  end

  def average_appointment_duration
    completed_appointments = appointments.where(status: 'completed')
    return 30 if completed_appointments.empty?

    total_duration = completed_appointments.sum do |apt|
      (apt.ends_at - apt.scheduled_at) / 60 # in minutes
    end
    
    (total_duration / completed_appointments.count).round
  end

  private

  def npi_number_format
    return unless npi_number.present?
    
    unless npi_number.match?(/\A\d{10}\z/)
      errors.add(:npi_number, 'must be exactly 10 digits')
    end
  end

  def geocode_practice_address
    return unless practice_address.present? && practice_city.present? && practice_state.present?
    
    full_address = "#{practice_address}, #{practice_city}, #{practice_state} #{practice_zip}"
    coordinates = Geocoder.coordinates(full_address)
    
    if coordinates
      self.practice_location = "POINT(#{coordinates[1]} #{coordinates[0]})"
    end
  end
end