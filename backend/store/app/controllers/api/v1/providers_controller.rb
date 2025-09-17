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
    
    # Cache availability for 5 minutes
    cache_key = "provider_availability_#{@provider.id}_#{date}"
    
    availability_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      calculate_detailed_availability(@provider, date)
    end

    render json: availability_data
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
  
  def calculate_detailed_availability(provider, date)
    schedule = provider.schedule_for_date(date)
    return { available: false, slots: [] } unless schedule&.is_available?

    slots = generate_time_slots(provider, date, schedule)
    
    {
      date: date,
      available: true,
      slots: slots,
      provider_info: {
        average_wait_time: provider.average_wait_time || 15,
        next_available: find_next_available_slot(provider, date)
      }
    }
  end

  def generate_time_slots(provider, date, schedule)
    slots = []
    current_time = Time.zone.parse("#{date} #{schedule.start_time}")
    end_time = Time.zone.parse("#{date} #{schedule.end_time}")
    slot_duration = schedule.slot_duration_minutes.minutes
    buffer_time = provider.booking_buffer_minutes.minutes

    # Get existing appointments for the day
    existing_appointments = provider.appointments
                                   .where(scheduled_at: date.beginning_of_day..date.end_of_day)
                                   .where(status: ['confirmed', 'requested'])

    while current_time < end_time
      # Check for conflicts
      conflict = existing_appointments.any? do |apt|
        apt.scheduled_at <= current_time && apt.ends_at > current_time
      end

      # Check buffer time
      too_close = existing_appointments.any? do |apt|
        (apt.scheduled_at - current_time).abs < buffer_time
      end

      unless conflict || too_close
        slots << {
          time: current_time.strftime('%H:%M'),
          datetime: current_time.iso8601,
          available: true,
          slot_type: determine_slot_type(current_time)
        }
      end

      current_time += slot_duration
    end

    slots
  end

  def determine_slot_type(time)
    hour = time.hour
    case hour
    when 6..11 then 'morning'
    when 12..16 then 'afternoon'  
    when 17..20 then 'evening'
    else 'other'
    end
  end

  def find_next_available_slot(provider, start_date)
    # Look ahead up to 30 days to find next available slot
    (start_date..start_date + 30.days).each do |date|
      schedule = provider.schedule_for_date(date)
      next unless schedule&.is_available?

      slots = generate_time_slots(provider, date, schedule)
      first_slot = slots.find { |slot| slot[:available] }
      
      if first_slot
        return {
          date: date.iso8601,
          time: first_slot[:time],
          datetime: first_slot[:datetime]
        }
      end
    end

    nil
  end
  end