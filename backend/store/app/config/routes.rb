Rails.application.routes.draw do
    devise_for :users, controllers: {
        registrations: 'users/registrations',
        sessions: 'users/sessions', 
    }

    root 'dashboard#index'

    # API Routes
    namespace :api do
        namespace :v1 do
            resources :appointments do
                member do 
                    patch :confirm
                    patch :cancel 
                end
            end

            resources :providers do 
                member do
                    get :availability
                end
            end

            resources :patients, only: [:show, :update]
            resources :appointment_types, only: [:index, :show]
        end
    end

    # Web Routes
    resources :dashboard, only: [:index]
    resources :appointments 
    resources :providers, only: [:index, :show]

    # Admin Routes
    namespace :admin do 
        resources :users
        resources :appointments
        resources :providers
        root 'dashboard#index'
    end

    # Health check 
    get '/health', to: 'application#health'
end