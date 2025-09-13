class AppointmentSerializer
    include JSONAPI::Serializer
  
    attributes :id, :scheduled_at, :ends_at, :status, :reason_for_visit, 
               :notes, :is_telemedicine, :confirmation_number, :created_at
  
    belongs_to :patient, serializer: PatientSerializer
    belongs_to :provider, serializer: ProviderSerializer
    belongs_to :appointment_type, serializer: AppointmentTypeSerializer
  
    attribute :duration_minutes do |appointment|
      appointment.duration_minutes
    end
  
    attribute :can_be_cancelled do |appointment|
      appointment.can_be_cancelled?
    end
  
    attribute :is_upcoming do |appointment|
      appointment.is_upcoming?
    end
  end