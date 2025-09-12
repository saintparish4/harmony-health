class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Authorization
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render json: { error: 'Access denied' }, status: :forbidden }
      format.html { redirect_to root_path, alert: 'Access denied.' }
    end
  end

  # HIPAA Compliance: Log all access
  after_action :log_user_activity

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end

  def current_patient
    current_user&.patient
  end

  def current_provider
    current_user&.provider
  end

  private

  def log_user_activity
    return unless current_user

    Rails.logger.info({
      user_id: current_user.id,
      action: "#{controller_name}##{action_name}",
      ip: request.remote_ip,
      user_agent: request.user_agent,
      timestamp: Time.current
    }.to_json)
  end
end