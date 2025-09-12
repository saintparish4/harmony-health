class Patient < ApplicationRecord
    belongs_to :user
    has_many :appointments, dependent: :destroy
    has_many :insurance_plans, dependent: :destroy
    has_many :providers, -> { distinct }, through: :appointments

    # Encryptions for HIPAA compliance
    encrypts :address, :emergency_contact_name, :emergency_contact_phone
    encrypts :medical_history, :allergies, :current_medications

    # Validations
    validates :date_of_birth, presence: true
    validates :gender, inclusion: { in: %w[male female other prefer_not_to_say] } 
    validate :age_must_be_reasonable

    # Callbacks
    before_save :geocode_address, if: :address_changed?
    after_create :create_audit_log

    # Scopes
    scope :by_age_range, ->(min, max) {
        where(date_of_birth: (Date.current - max.years)..(Date.current - min.years))
    }
    scope :by_location, ->(lat, lng, radius_km) {
        where("ST_DWithin(location, ST_MakePoint(?, ?), ?)", lng, lat, radius_km * 1000)
    }

    # Instance methods
    def age
        return nil unless date_of_birth
        ((Date.current - date_of_birth) / 365).to_i
    end

    def primary_insurance
        insurance_plans.where(is_primary: true).first
    end

    def upcoming_appointments
        appointments.where('scheduled_at > ?', Time.current)
            .where(status: ['confirmed', 'requested'])
            .order(:scheduled_at)
    end

    def has_upcoming_appointment_with?(provider)
        upcoming_appointments.exists?(provider: provider)
    end

    private

    def age_must_be_reasonable
        return unless date_of_birth

        age = self.age
        errors.add(:date_of_birth, 'must result in reasonable age') if age < 0 || age > 150
    end

    def geocode_address
        return unless address.present? && city.present? && state.present?

        full_address = "#{address}, #{city}, #{state} #{zip_code}"
        coordinates = Geocoder.coordinates(full_address)

        if coordinates
            self.location = "POINT(#{coordinates[1]} #{coordinates[0]})"
        end
    end

    def create_audit_log
        Rails.logger.info "Patient created: #{id} for user: #{user_id}"
    end
end