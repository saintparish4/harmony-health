class InsurancePlan < ApplicationRecord
  belongs_to :patient

  # Enums
  enum verification_status: { 
    pending: 0, 
    verified: 1, 
    rejected: 2, 
    error: 3 
  }

  # Validations
  validates :insurance_company, presence: true
  validates :plan_name, presence: true
  validates :member_id, presence: true
  validates :effective_date, presence: true
  validate :expiration_date_after_effective_date

  # Callbacks
  after_create :verify_eligibility_async

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :active, -> { where('effective_date <= ? AND (expiration_date IS NULL OR expiration_date >= ?)', Date.current, Date.current) }
  scope :by_company, ->(company) { where(insurance_company: company) }

  # Instance methods
  def active?
    return false unless effective_date
    
    current_date = Date.current
    effective_date <= current_date && (expiration_date.nil? || expiration_date >= current_date)
  end

  def verified?
    verification_status == 'verified'
  end

  def expired?
    expiration_date.present? && expiration_date < Date.current
  end

  def copay_for_service_type(service_type)
    case service_type&.downcase
    when 'primary_care', 'general'
      copay_primary
    when 'specialist'
      copay_specialist
    else
      copay_primary # default to primary care copay
    end
  end

  def needs_verification?
    pending? || (verified? && verification_date < 30.days.ago)
  end

  private

  def verify_eligibility_async
    InsuranceVerificationJob.perform_later(self)
  end

  def expiration_date_after_effective_date
    return unless effective_date && expiration_date

    errors.add(:expiration_date, 'must be after effective date') if expiration_date <= effective_date
  end
end
