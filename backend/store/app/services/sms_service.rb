class SmsService
    def self.send_confirmation(appointment)
        message = build_confirmation_message(appointment)
        send_sms(appointment.patient.user.phone, message)
    end

    def self.send_24_hour_reminder(appointment)
        message = build_24_hour_reminder_message(appointment)
        send_sms(appointment.patient.user.phone, message)
    end

    def self.send_2_hour_reminder(appointment)
        message = build_2_hour_reminder_message(appointment)
        send_sms(appointment.patient.user.phone, message)
    end

    private

    def self.send_sms(phone, message)
        # Implementation would use Twilio or similar service
        Rails.logger.info "SMS to #{phone}: #{message}"
    end

    def self.build_confirmation_message(appointment)
        "Your appointment with Dr. #{appointment.provider.user.last_name} on #{appointment.scheduled_at.strftime('%m/%d at %I:%M %p')} is confirmed. Confirmation number: #{appointment.confirmation_number}"
    end

    def self.build_24_hour_reminder_message(appointment)
        "Reminder: You have an appointment tomorrow with Dr. #{appointment.provider.user.last_name} at #{appointment.scheduled_at.strftime('%I:%M %p')}. See you soon!" 
    end
end
