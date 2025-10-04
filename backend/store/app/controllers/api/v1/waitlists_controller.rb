class Api::V1::WaitlistsController < Api::V1::BaseController
    before_action :authenticate_user!
  
    # GET /api/v1/waitlists
    def index
      @waitlists = current_user.patient.waitlists
                              .includes(:provider, :appointment_type)
                              .active
                              .by_priority
      
      render json: WaitlistSerializer.new(@waitlists).serializable_hash
    end
  
    # POST /api/v1/waitlists
    def create
      @waitlist = current_user.patient.waitlists.build(waitlist_params)
      @waitlist.calculate_priority!
  
      if @waitlist.save
        render json: WaitlistSerializer.new(@waitlist).serializable_hash,
               status: :created
      else
        render json: { errors: @waitlist.errors }, status: :unprocessable_entity
      end
    end
  
    # PATCH /api/v1/waitlists/:id/claim
    def claim
      @waitlist = Waitlist.find(params[:id])
      appointment = Appointment.find(params[:appointment_id])
  
      if @waitlist.notified? && @waitlist.expires_at > Time.current
        # Assign appointment to patient
        appointment.update!(
          patient: @waitlist.patient,
          status: 'confirmed'
        )
        
        @waitlist.update!(status: 'claimed')
  
        # Cancel other notifications for this slot
        cancel_other_notifications(appointment)
  
        render json: {
          message: 'Appointment claimed successfully',
          appointment: AppointmentSerializer.new(appointment).serializable_hash
        }
      else
        render json: { error: 'Waitlist slot expired or invalid' },
               status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/waitlists/:id
    def destroy
      @waitlist = current_user.patient.waitlists.find(params[:id])
      @waitlist.update(status: 'cancelled')
      head :no_content
    end
  
    private
  
    def waitlist_params
      params.require(:waitlist).permit(
        :provider_id,
        :appointment_type_id,
        :preferred_date_start,
        :preferred_date_end,
        :notes,
        preferred_time_of_day: []
      )
    end
  
    def cancel_other_notifications(appointment)
      Waitlist.notified
              .where(provider: appointment.provider)
              .where.not(id: @waitlist.id)
              .update_all(status: 'expired')
    end
  end