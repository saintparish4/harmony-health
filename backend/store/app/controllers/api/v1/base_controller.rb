class Api::V1::BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_api_user!

rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
rescue_from ActionController::ParameterMissing, with: :parameter_missing

private

def authenticate_api_user!
    # For now, use session-based auth. In future, we can use API keys or JWT tokens
    authenticate_user!
end

def record_not_found(exception)
    render json: {
        error: "Record not found"
        message: exception.message
    }, status: :not_found
end

def record_invalid(exception)
    render json: {
        error: "Validation failed",
        details: exception.record.errors.full_messages
    }, status: :unprocessable_entity
end

def parameter_missing(exception)
    render json: {
        error: 'Missing parameter',
        message: exception.message 
    }, status: :bad_request 
end

def pagination_params
    {
        page: params[:page]&.to_i || 1,
        per_page: [params[:per_page]&.to_i || 20, 100].min 
    }
end
end