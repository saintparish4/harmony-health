class AvailabilityChannel < ApplicationCable::Channel
    def subscribed
        return reject unless params[:provider_id].present?

        provider = Provider.find(params[:provider_id])
        stream_for provider
    end

    def unsubscribed
        # Cleanup 
    end
end
