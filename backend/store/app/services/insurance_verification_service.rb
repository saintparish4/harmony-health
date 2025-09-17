class InsuranceVerificationService
    include HTTParty
    base_uri Rails.application.credentials.insurance_api_base_url

    def initialize(insurance_plan)
        @insurance_plan = insurance_plan
    end

    def verify_eligibility
        response = perform_eligibility_check

        if response.success?
            update_verification_status(response.parsed_response)
        else
            handle_verification_error(response)
        end
    end
    
    def verify_with_provider(provider)
        return false unless @insurance_plan.verified?

        provider.accepted_insurances.include?(@insurance_plan.insurance_company)
    end

    private

    def perform_eligibility_check
        self.class.post('/eligibility', {
            body: verification_payload.to_json,
            headers: {
                'Content-Type' => 'application/json',
                'Authorization' => "Bearer #{api_token}" 
            }
        })
    rescue => e
        Rails.logger.error "Insurance verification failed: #{e.message}"
        OpenStruct.new(success?: false, error: e.message)
    end

    def verification_payload
        {
            member_id: @insurance_plan.member_id,
            insurance_company: @insurance_plan.insurance_company,
            group_number: @insurance_plan.group_number,
            service_date: Date.cirrent.iso8601 
        }
    end

    def update_verification_status(response_data)
        @insurance_plan.update!(
            verification_status: response_data['eligible'] ? 'verified' : 'rejected',
            verification_date: Time.current,
            verification_details: response_data,
            copay_amount: response_data['copay_amount'] 
        )
    end

    def handle_verification_error(response)
        @insurance_plan.update!(
            verification_status: 'error',
            verification_date: Time.current,
            verification_error: response.parsed_response&.dig('error') || 'Unknown error' 
        )
    end

    def api_token
        Rails.application.credentials.insurance_api_token
    end
end
