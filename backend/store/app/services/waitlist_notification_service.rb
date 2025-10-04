class WaitlistNotificationService
    CLAIM_WINDOW_MINUTES = 15 # How long patient has to claim
  
    def initialize(appointment)
      @appointment = appointment
    end
  
    def notify_waitlist
      return unless @appointment.cancelled?
  
      eligible_patients = find_eligible_patients
      return if eligible_patients.empty?
  
      # Notify in priority order
      eligible_patients.each_with_index do |waitlist, index|
        if index == 0
          notify_patient(waitlist)
          break
        end
      end
    end
  
    private
  
    def find_eligible_patients
      time_of_day = determine_time_of_day(@appointment.start_time)
      
      Waitlist.active
              .where(provider: @appointment.provider)
              .where(appointment_type: @appointment.appointment_type)
              .for_time_slot(@appointment.start_time.to_date, time_of_day)
              .by_priority
    end
  
    def notify_patient(waitlist)
      waitlist.update!(
        status: 'notified',
        notified_at: Time.current,
        expires_at: CLAIM_WINDOW_MINUTES.minutes.from_now
      )
  
      # Send SMS notification
      WaitlistNotificationJob.perform_async(
        waitlist.id,
        @appointment.id
      )
  
      # Schedule expiration check
      WaitlistExpirationJob.perform_in(
        CLAIM_WINDOW_MINUTES.minutes,
        waitlist.id,
        @appointment.id
      )
    end
  
    def determine_time_of_day(datetime)
      hour = datetime.hour
      case hour
      when 6..11 then 'morning'
      when 12..16 then 'afternoon'
      when 17..20 then 'evening'
      else 'other'
      end
    end
  end