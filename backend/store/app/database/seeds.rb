# Create appointment types
AppointmentType.create!([
    {
        name: 'Initial Consultation',
        description: 'Initial visit with new patient',
        duration_minutes: 60,
        requires_preparation: true,
        preparation_instructions: 'Please bring insurance card and photo ID'
    },
    {
        name: 'Follow-up Visit',
        description: 'Regular follow-up visit',
        duration_minutes: 30 
    },
    {
        name: 'Annual Physical',
        description: 'Comprehensive annual health examination',
        duration_minutes: 45,
        requires_preparation: true,
        preparation_instructions: 'Fasting required for 12 hours before appointment' 
    },
    {
        name: 'Telehealth Consultation',
        description: 'Virtual consultation via video call',
        duration_minutes: 30,
        telemedicine_eligible: true 
    }
])

# Create admin user
admin_user = User.create!(
    email: 'admin@harmonyhealth.com',
    password: 'password123',
    first_name: 'Admin',
    last_name: 'User',
    phone: '+1234567890',
    role: 'super_admin',
    status: 'active',
    confirmed_at: Time.current 
)

