# frozen_string_literal: true

class WaitlistExpirationJob < ApplicationJob
  queue_as :default

  def perform(waitlist_id, appointment_id)
    waitlist = Waitlist.find(waitlist_id)
    appointment = Appointment.find(appointment_id)

    # If still notified (not claimed), move to next person
    if waitlist.notified? && appointment.cancelled?
      waitlist.update(status: 'expired')

      # Notify next person on waitlist
      WaitlistNotificationService.new(appointment).notify_waitlist
    end
  end
end
