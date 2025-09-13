class AppointmentReminderJob < ApplicationJob
    queue_as :default

    def perform(appointment, reminder_type)
        return unless appointment.confirmed?
        return if appointment.reminder_sent[reminder_type]

        case reminder_type
        when "24_hours"
            send_24_hour_reminder(appointment)
        when "2_hours"
            send_2_hour_reminder(appointment)
        end

        # Mark reminder as sent
        appointment.update!(
            reminder_sent: appointment.reminder_sent.merge(reminder_type => true) 
        )
    end

    private 

    def send_24_hour_reminder(appointment)
        AppointmentMailer.reminder_24_hours(appointment).deliver_now
        SmsService.send_24_hour_reminder(appointment) if appointment.patient.user.phone.present?
    end

    def send_2_hour_reminder(appointment)
        SmsService.send_2_hour_reminder(appointment) if appointment.patient.user.phone.present?
    end
end