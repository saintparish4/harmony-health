class AuditService
    def self.log_access(user, resource, action, additional_info = {})
      AuditLog.create!(
        user: user,
        resource_type: resource.class.name,
        resource_id: resource.id,
        action: action,
        ip_address: additional_info[:ip_address],
        user_agent: additional_info[:user_agent],
        additional_data: additional_info[:data],
        timestamp: Time.current
      )
    end
  
    def self.log_phi_access(user, patient, action, details = {})
      PhiAccessLog.create!(
        user: user,
        patient: patient,
        action: action,
        accessed_fields: details[:fields],
        purpose: details[:purpose],
        ip_address: details[:ip_address],
        timestamp: Time.current
      )
    end
  end