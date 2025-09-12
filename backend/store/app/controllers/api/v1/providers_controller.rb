class Api::V1::ProvidersController < Api::V1::BaseController
    before_action :set_provider, only: [:show, :update]
  
    def index
      @providers = Provider.includes(:user)
                          .accepting_patients
                          .page(pagination_params[:page])
                          .per(pagination_params[:per_page])
  
      @providers = filter_providers(@providers)
  
      render json: ProviderSerializer.new(@providers, include: [:user])
    end
  
    def show
      render json: ProviderSerializer.new(@provider, include: [:user])
    end
  
    def update
      authorize_provider_access
  
      if @provider.update(provider_params)
        render json: ProviderSerializer.new(@provider)
      else
        render json: { errors: @provider.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def availability
      @provider = Provider.find(params[:id])
      date = Date.parse(params[:date]) rescue Date.current
      
      schedule = @provider.schedule_for_date(date)
      available_slots = calculate_available_slots(@provider, date)
  
      render json: {
        date: date,
        available: schedule&.is_available? || false,
        slots: available_slots
      }
    end
  
    private
  
    def set_provider
      @provider = Provider.find(params[:id])
    end
  
    def authorize_provider_access
      unless current_user.provider? && current_provider == @provider
        render json: { error: 'Access denied' }, status: :forbidden
      end
    end
  
    def provider_params
      params.require(:provider).permit(
        :bio, :practice_name, :practice_address, :practice_city, 
        :practice_state, :practice_zip, :accepting_new_patients,
        :booking_buffer_minutes, specialties: [], accepted_insurances: []
      )
    end
  
    def filter_providers(providers)
      if params[:specialty].present?
        providers = providers.by_specialty(params[:specialty])
      end
  
      if params[:insurance].present?
        providers = providers.by_insurance(params[:insurance])
      end
  
      if params[:lat].present? && params[:lng].present?
        radius = params[:radius]&.to_f || 25.0 # Default 25km radius
        providers = providers.by_location(params[:lat].to_f, params[:lng].to_f, radius)
      end
  
      if params[:min_rating].present?
        providers = providers.by_rating(params[:min_rating].to_f)
      end
  
      providers
    end
  
    def calculate_available_slots(provider, date)
      schedule = provider.schedule_for_date(date)
      return [] unless schedule&.is_available?
  
      # Generate time slots based on schedule
      slots = []
      current_time = Time.zone.parse("#{date} #{schedule.start_time}")
      end_time = Time.zone.parse("#{date} #{schedule.end_time}")
      slot_duration = schedule.slot_duration_minutes.minutes
  
      while current_time < end_time
        # Check if slot conflicts with existing appointments
        conflict = provider.appointments
                          .where(status: ['confirmed', 'requested'])
                          .where('scheduled_at <= ? AND ends_at > ?', current_time, current_time)
                          .exists?
  
        unless conflict
          slots << {
            time: current_time.strftime('%H:%M'),
            datetime: current_time.iso8601,
            available: true
          }
        end
  
        current_time += slot_duration
      end
  
      slots
    end
  end