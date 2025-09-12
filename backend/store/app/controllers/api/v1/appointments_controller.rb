class Api::V1::AppointmentsController < Api::V1::BaseController
    before_action :set_appointment, only: [:show, :update, :destroy]
    before_action :authorize_appointment_access, only: [:show, :update, :destroy]

    def index
        @appointments = current_user.profile.appointments
                                    .includes(:patient, :provider, :appointment_type)
                                    .page(pagination_params[:page])
                                    .per(pagination_params[:per_page])
        @appointments = filter_appointments(@appointments)

        render json: AppointmentSerializer.new(@appointments, include: [:patient, :provider, :appointment_type])
    end

    def show
        render json: AppointmentSerializer.new(@appointment, include: [:patient, :provider, :appointment_type])
    end

    def create
        @appointment = Appointment.new(appointment_params)

        if current_user.patient?
            @appointment.patient = current_patient
        elseif current_user.provider?
            @appointment.provider = current_provider
        end

        if @appointment.save
            render json: AppointmentSerializer.new(@appointment), status: :created
        else
            render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        if @appointment.update(appointment_update_params)
            render json: AppointmentSerializer.new(@appointment)
        else
            render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
        if @appointment.can_be_cancelled?
            @appointment.cancel!
            render json: { message: 'Appointment cancelled successfully' }
        else
            render json: { error: 'Appointment cannot be cancelled' }, status: :unprocessable_entity
        end
    end

    def confirmable
        @appointment = Appointment.find(params[:id])
        authorize_appointment_access

        if @appointment.may_confirm?
            @appointment.confirm!
            render json: AppointmentSerializer.new(@appointment)
        else
            render json: { error: 'Appointment cannot be confirmed' }, status: :unprocessable_entity
        end
    end

    private

    def set_appointment
        @appointment = Appointment.find(params[:id])
    end

    def authorize_appointment_access
        unless current_user.can_manage?(@appointment)
            render json: { error: 'Access denied' }, status: :forbidden
        end
    end

    def appointment_params
        params.require(:appointment).permit(
            :provider_id, :patient_id, :appointment_type_id, :scheduled_at, :reason_for_visit, :is_telemedicine
        )
    end

    def appointment_update_params
        allowed_params = [:reason_for_visit, :notes]
        allowed_params += [:provider_notes] if current_user.provider?
        params.require(:appointment).permit(allowed_params)
    end

    def filter_appointments(appointments)
        appointments = appointments.where(status: params[:status]) if params[:status].present?
        appointments = appointments.where('scheduled_at >= ?', Date.parse(params[:start_date])) if params[:start_date].present?
        appointments = appointments.where('scheduled_at <= ?', Date.parse(params[:end_date])) if params[:end_date].present?
        appointments 
    end
end


