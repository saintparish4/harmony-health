# Harmony Health Backend

A comprehensive healthcare appointment management system built with Ruby on Rails 8.0.2, designed with HIPAA compliance and modern healthcare workflows in mind.

## 🏗️ Current MVP Status

This backend is currently at **MVP (Minimum Viable Product)** level with a solid foundation but missing essential configuration files and setup.

### ✅ What's Implemented

#### Core Architecture
- **Rails 8.0.2** with modern App Router structure
- **PostgreSQL** with PostGIS extensions for geospatial features
- **UUID primary keys** for enhanced security
- **API-first design** with versioned endpoints (`/api/v1/`)
- **Service-oriented architecture** with dedicated service classes

#### Security & Compliance
- **HIPAA-compliant** design with encrypted sensitive fields
- **Paper trail** for audit logging on all models
- **PHI access logging** with detailed audit trails
- **Role-based authorization** (patient, provider, admin, super_admin)
- **Rate limiting** middleware included

#### Models & Business Logic
- **User Management**: Devise authentication with multiple roles
- **Patient System**: Medical history, insurance, geocoded addresses
- **Provider System**: NPI validation, specialties, practice locations
- **Appointment System**: State machine with smart scheduling
- **Smart Scheduling Service**: AI-powered appointment matching
- **Real-time Updates**: ActionCable channels for live updates

#### Dependencies (All Updated)
- `devise` - Authentication
- `aasm` - State machine for appointments
- `paper_trail` - Audit logging
- `geocoder` - Address geocoding
- `phonelib` - Phone validation
- `jsonapi-serializer` - API serialization
- `kaminari` - Pagination
- `sidekiq` - Background jobs
- `redis` - Caching and jobs
- `rack-cors` - CORS handling

## ❌ Missing Configuration Files

The following essential files need to be created to make the application functional:

### 1. Core Rails Configuration
```
config/
├── application.rb          # Main application configuration
├── boot.rb                # Boot configuration
├── environment.rb         # Environment initialization
├── database.yml           # Database configuration
└── environments/
    ├── development.rb     # Development environment
    ├── test.rb           # Test environment
    └── production.rb     # Production environment
```

### 2. Gem Initializers
```
config/initializers/
├── devise.rb              # Devise authentication setup
├── paper_trail.rb         # Audit logging configuration
├── geocoder.rb            # Geocoding service setup
├── sidekiq.rb             # Background job configuration
├── cors.rb                # CORS policy setup
└── redis.rb               # Redis configuration
```

### 3. Missing Controllers
```
app/controllers/
├── dashboard_controller.rb        # Main dashboard
├── users/
│   ├── registrations_controller.rb
│   └── sessions_controller.rb
└── admin/
    └── dashboard_controller.rb
```

### 4. Missing Views
```
app/views/
├── dashboard/
│   └── index.html.erb
├── layouts/
│   └── application.html.erb (needs content)
└── users/
    ├── registrations/
    └── sessions/
```

### 5. Environment Configuration
```
.env                        # Environment variables
.env.example               # Example environment file
```

## 🚀 Setup Instructions

### Prerequisites
- Ruby 3.2+
- PostgreSQL 14+
- Redis 6+
- Node.js 18+ (for asset compilation)

### Installation Steps

1. **Install Dependencies**
   ```bash
   bundle install
   ```

2. **Create Configuration Files** (See missing files above)

3. **Setup Database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start Services**
   ```bash
   # Start Redis
   redis-server

   # Start Sidekiq (in separate terminal)
   bundle exec sidekiq

   # Start Rails server
   rails server
   ```

## 📊 Database Schema

### Core Tables
- `users` - Authentication and basic user info
- `patients` - Patient profiles with medical data
- `providers` - Healthcare provider information
- `appointments` - Appointment scheduling and management
- `appointment_types` - Types of appointments
- `provider_schedules` - Provider availability
- `insurance_plans` - Patient insurance information

### Key Features
- **UUID primary keys** for all tables
- **Encrypted fields** for PHI data
- **PostGIS support** for location-based features
- **Audit trails** on all models

## 🔧 API Endpoints

### Authentication
- `POST /users/sign_in` - User login
- `POST /users/sign_up` - User registration
- `DELETE /users/sign_out` - User logout

### Appointments
- `GET /api/v1/appointments` - List appointments
- `POST /api/v1/appointments` - Create appointment
- `PATCH /api/v1/appointments/:id/confirm` - Confirm appointment
- `PATCH /api/v1/appointments/:id/cancel` - Cancel appointment

### Providers
- `GET /api/v1/providers` - List providers
- `GET /api/v1/providers/:id/availability` - Check availability

## 🧪 Testing

### Test Setup
```bash
# Install test dependencies
bundle install

# Run tests
bundle exec rspec
```

### Test Coverage
- Model validations and associations
- Controller actions and authorization
- Service class business logic
- API endpoint responses

## 🔒 Security Features

### HIPAA Compliance
- **Data Encryption**: Sensitive fields encrypted at rest
- **Audit Logging**: All PHI access logged
- **Access Controls**: Role-based permissions
- **Session Management**: Secure session handling

### Security Headers
- CORS configuration
- Rate limiting
- SSL enforcement (production)
- Security headers middleware

## 📈 Performance Features

### Caching
- Redis-based caching
- Query optimization
- Background job processing

### Real-time Features
- WebSocket connections
- Live appointment updates
- Availability broadcasting

## 🚀 Deployment

### Production Requirements
- PostgreSQL database
- Redis server
- Sidekiq workers
- SSL certificates
- Environment variables

### Environment Variables
```bash
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=your_secret_key
DEVISE_SECRET_KEY=your_devise_secret
```

## 📝 Development Notes

### Code Quality
- RuboCop for code style
- Brakeman for security scanning
- RSpec for testing
- FactoryBot for test data

### Architecture Decisions
- **Service Objects**: Business logic separation
- **Serializers**: Consistent API responses
- **State Machines**: Appointment workflow management
- **Background Jobs**: Async processing for notifications

## 🔄 Next Steps for Production

1. **Complete Configuration Setup**
2. **Add Comprehensive Tests**
3. **Implement Error Handling**
4. **Add API Documentation**
5. **Setup Monitoring & Logging**
6. **Configure CI/CD Pipeline**
7. **Add Health Checks**
8. **Implement Backup Strategy**

## 📞 Support

For questions about this backend implementation, refer to the code comments and inline documentation throughout the codebase.
