Rails.application.routes.draw do
  namespace :app do
    root to: "home#index"
  end
  root to: "app/home#index"
  devise_for :users

  get "pages/:page" => "pages#show", as: :pages

  namespace :rui do
    get "about", to: "pages#about"
    get "pricing", to: "pages#pricing"
    get "dashboard", to: "pages#dashboard"
    get "properties", to: "pages#properties"
    get "inbox", to: "pages#inbox"
    get "calendar", to: "pages#calendar"
    get "insights", to: "pages#insights"
    get "bookings", to: "pages#bookings"
    get "new_booking", to: "pages#new_booking"
    get "booking", to: "pages#booking"
    get "edit_booking", to: "pages#edit_booking"
    get "help_center", to: "pages#help_center"
    get "changelog", to: "pages#changelog"
    get "api", to: "pages#api"
    get "privacy_policy", to: "pages#privacy_policy"
    get "terms", to: "pages#terms"
    get "contact", to: "pages#contact"
    get "account_payment_methods", to: "pages#account_payment_methods"
    get "account_payouts", to: "pages#account_payouts"
    get "account_notifications", to: "pages#account_notifications"
    get "account_preferences", to: "pages#account_preferences"
  end

  if Rails.env.development?
    # Visit the start page for Rails UI any time at /railsui/start
    mount Railsui::Engine, at: "/railsui"
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
