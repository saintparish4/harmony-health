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
  around_action :log_phi_access

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

  def log_phi_access
    yield
  ensure
    if current_user && involves_phi?
      AuditService.log_access(
        current_user,
        detected_resource,
        "#{controller_name}##{action_name}",
        {
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          data: sanitized_params
        }
      )
    end
  end

  def involves_phi?
    # Determine if the current action involves PHI
    phi_controllers = %w[patients appointments providers]
    phi_controllers.include?(controller_name)
  end

  def detected_resource
    # Try to detect the main resource being accessed
    if params[:id].present?
      controller_name.classify.constantize.find_by(id: params[:id])
    else
      controller_name.classify.constantize
    end
  rescue
    OpenStruct.new(class: controller_name.classify, id: params[:id])
  end

  def sanitized_params
    # Remove sensitive parameters from logs
    params.except(:password, :password_confirmation, :medical_history, :notes)
          .to_unsafe_h
  end
end