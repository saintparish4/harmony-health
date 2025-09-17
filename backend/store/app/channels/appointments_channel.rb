class AppointmentsChannel < ApplicationCable::Channel
    def subscribed
        if current_user.patient?
            stream_for current_user.patient
        elsif current_user.provider?
            stream_for current_user.provider
        end
    end

    def unsubscribed
        # Cleanup when channel is unsubscribed
    end
end

