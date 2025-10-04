# frozen_string_literal: true

class WaitlistNotificationJob < ApplicationJob
  queue_as :urgent

  def perform(waitlist_id, appointment_id)
    waitlist = Waitlist.find(waitlist_id)
    appointment = Appointment.find(appointment_id)

    # SMS notification
    message = "Great news! A #{appointment.appointment_type.name} appointment " \
              "with Dr. #{appointment.provider.last_name} is available on " \
              "#{appointment.start_time.strftime('%B %d at %I:%M %p')}. " \
              "Claim it now: #{claim_url(waitlist)}"

    NotificationService.send_sms(
      to: waitlist.patient.phone_number,
      body: message
    )

    # Email notification
    WaitlistMailer.slot_available(waitlist, appointment).deliver_later
  end

  private

  def claim_url(waitlist)
    "#{ENV['FRONTEND_URL']}/waitlist/#{waitlist.id}/claim"
  end
end