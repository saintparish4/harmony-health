class User < ApplicationRecord
    devise :database_authenticatable, :registerable, :recoverable,
           :rememberable, :validatable, :confirmable, :trackable


    # Enums
    enum role: { patient: 0, provider: 1, admin: 2, super_admin: 3 }
    enum status: { active: 0, inactive: 1, suspended: 2, pending: 3 }

    # Associations
    has_one :patient, dependent: :destroy
    has_one :provider, dependent: :destroy

    # Encryptions for HIPAA compliance
    encrypts :phone

    # Validations
    validates :first_name, :last_name, :phone, presence: true
    validates :phone, phone: true
    validates :role, presence: true

    # callbacks
    before_validation :normalize_phone

    # Instance Methods
    def full_name
        "#{first_name} #{last_name}"
    end

    def profile
        return patient if patient?
        return provider if provider?
        self
    end

    def can_manage?(resource)
        case role
        when 'super_admin'
            true
        when 'admin'
            true
        when 'provider'
            resource.is_a?(Appointment) && resource.provider_id == provider&.id
        when 'patient'
            resource.is_a?(Appointment) && resource.patient_id == patient&.id
        else
            false
        end
    end

    private

    def normalize_phone
        self.phone = Phonelib.parse(phone).e164 if phone.present?
    end
end
