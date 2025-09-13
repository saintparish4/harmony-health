class ProviderSerializer
    include JSONAPI::Serializer
  
    attributes :id, :npi_number, :specialties, :bio, :practice_name, 
               :practice_address, :practice_city, :practice_state, 
               :rating, :total_reviews, :accepting_new_patients
  
    belongs_to :user, serializer: UserSerializer
  
    attribute :distance do |provider, params|
      if params[:user_lat] && params[:user_lng]
        # Calculate distance if user location provided
        # This would be implemented with PostGIS functions
      end
    end
  end