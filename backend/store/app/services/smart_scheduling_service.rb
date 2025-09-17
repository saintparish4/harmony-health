class SmartSchedulingService
  attr_reader :patient, :filters, :preferences

  def initialize(patient, filters = {}, preferences = {})
    @patient = patient
    @filters = filters
    @preferences = preferences
  end

  def find_optimal_appointments(limit = 10)
    providers = find_eligible_providers
    appointments = []

    providers.each do |provider|
      provider_appointments = generate_appointment_options(provider)
      appointments.concat(provider_appointments)
    end

    # Score and rank appointments
    scored_appointments = score_appointments(appointments)
    scored_appointments.first(limit)
  end

  private

  def find_eligible_providers
    providers = Provider.accepting_patients.includes(:user)

    # Apply filters
    providers = providers.by_specialty(filters[:specialty]) if filters[:specialty]
    providers = providers.by_insurance(patient.primary_insurance&.insurance_company)

    if filters[:location]
      providers = providers.by_location(
        filters[:location][:lat],
        filters[:location][:lng],
        filters[:max_distance] || 25
      )
    end

    providers = providers.by_rating(filters[:min_rating] || 3.0)
    providers.limit(20) # Reasonable limit for processing
  end

  def generate_appointment_options(provider)
    appointments = []
    start_date = Date.current + 1.day
    end_date = start_date + (filters[:date_range] || 30).days

    (start_date..end_date).each do |date|
      next unless provider.available_on?(date)

      available_slots = calculate_available_slots(provider, date)
      available_slots.each do |slot|
        appointments << {
          provider: provider,
          datetime: slot[:datetime],
          appointment_type: determine_appointment_type,
          estimated_wait_time: calculate_wait_time(provider, date)
        }
      end
    end

    appointments
  end

  def score_appointments(appointments)
    appointments.map do |apt|
      score = calculate_composite_score(apt)
      apt.merge(score: score)
    end.sort_by { |apt| -apt[:score] }
  end

  def calculate_composite_score(appointment)
    provider = appointment[:provider]
    datetime = appointment[:datetime]

    # Scoring factors (weights can be adjusted based on patient preferences)
    factors = {
      provider_rating: provider.rating * 0.25,
      distance: calculate_distance_score(provider) * 0.20,
      availability: calculate_availability_score(datetime) * 0.20,
      insurance_match: calculate_insurance_score(provider) * 0.15,
      patient_preference: calculate_preference_score(provider, datetime) * 0.20
    }

    factors.values.sum.round(2)
  end

  def calculate_distance_score(provider)
    return 5.0 unless filters[:location] && provider.practice_location

    # Distance scoring: closer = higher score
    distance = calculate_distance(provider)
    return 5.0 if distance <= 5
    return 3.0 if distance <= 15
    return 1.0 if distance <= 25
    0.0
  end

  def calculate_availability_score(datetime)
    # Prefer appointments sooner rather than later
    days_from_now = (datetime.to_date - Date.current).to_i
    return 5.0 if days_from_now <= 3
    return 4.0 if days_from_now <= 7
    return 3.0 if days_from_now <= 14
    return 2.0 if days_from_now <= 21
    1.0
  end

  def calculate_insurance_score(provider)
    return 5.0 if patient.primary_insurance &&
                  provider.accepts_insurance?(patient.primary_insurance.insurance_company)
    0.0
  end

  def calculate_preference_score(provider, datetime)
    score = 0.0

    # Time preferences
    if preferences[:preferred_times]
      hour = datetime.hour
      if preferences[:preferred_times].include?('morning') && hour < 12
        score += 2.0
      elsif preferences[:preferred_times].include?('afternoon') && hour.between?(12, 17)
        score += 2.0
      elsif preferences[:preferred_times].include?('evening') && hour > 17
        score += 2.0
      end
    end

    # Provider gender preference
    if preferences[:provider_gender] && provider.user.gender == preferences[:provider_gender]
      score += 1.0
    end

    # Language preference
    if preferences[:language] && provider.user.primary_language == preferences[:language]
      score += 1.0
    end

    score
  end

  def calculate_distance(provider)
    return Float::INFINITY unless filters[:location] && provider.practice_location

    # Simple distance calculation - in production use PostGIS functions
    lat1, lng1 = filters[:location][:lat], filters[:location][:lng]
    lat2 = provider.practice_location.y
    lng2 = provider.practice_location.x

    Geocoder::Calculations.distance_between([lat1, lng1], [lat2, lng2])
  end

  def determine_appointment_type
    # Logic to determine appropriate appointment type based on patient history
    if patient.appointments.completed.empty?
      AppointmentType.find_by(name: 'Initial Consultation')
    else
      AppointmentType.find_by(name: 'Follow-up Visit')
    end
  end

  def calculate_wait_time(provider, date)
    # Estimate wait time based on provider's schedule density
    day_appointments = provider.appointments.where(
      scheduled_at: date.beginning_of_day..date.end_of_day,
      status: ['confirmed', 'requested']
    ).count

    # Simple heuristic: more appointments = longer wait
    case day_appointments
    when 0..5 then 5   # Light day
    when 6..10 then 15 # Normal day
    when 11..15 then 25 # Busy day
    else 35            # Very busy day
    end
  end
end