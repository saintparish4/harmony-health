class PatientSerializer
    include JSONAPI::Serializer
  
    attributes :id, :date_of_birth, :gender, :city, :state, :primary_language
  
    belongs_to :user, serializer: UserSerializer
  
    attribute :age do |patient|
      patient.age
    end
  
    # Don't expose sensitive medical information in API
    attribute :has_medical_history do |patient|
      patient.medical_history.present?
    end
  end
  