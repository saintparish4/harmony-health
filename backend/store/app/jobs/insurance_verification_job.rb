class InsuranceVerificationJob < ApplicationJob
    queue_as :default

    def perform(insurance_plan)
        InsuranceVerificationService.new(insurance_plan).verify_eligibility
    end
end
