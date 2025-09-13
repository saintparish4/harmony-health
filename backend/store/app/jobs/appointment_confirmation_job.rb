class AppointmentConfirmationJob < ApplicationJob
  queue_as :high_priority

  def perform(appointment)
    # Send confirmation email to patient 
    AppointmentMailer.confirmation_email(appointment).deliver_now

    # Send SMS reminder if phone number available
    if appointment.patient.user.phone.present?
      SmsService.send_confirmation(appointment)
    end

    # Schedule reminders jobs
    schedule_reminders(appointment)
  end

  private

  def schedule_reminders(appointment)
    # 24-hour reminder
    reminder_time = appointment.scheduled_at - 24.hours
    if reminder_time > Time.current
      AppointmentReminderJob.set(wait_until: reminder_time).perform_later(appointment, "24_hours")
    end

    # 2-hour reminder
    reminder_time = appointment.scheduled_at - 2.hours
    if reminder_time > Time.current
      AppointmentReminderJob.set(wait_until: reminder_time).perform_later(appointment, "2_hours")
    end
  end
end