Rails.application.routes.draw do
  namespace :app do
    resources :malwares
    resources :reports
    resources :hosts
    resources :predictions
    resources :threat_actors
    resources :indicators
    resources :events
    resources :sources
    root to: "home#index"
  end
  root to: "app/home#index"
  devise_for :users

  get "pages/:page" => "pages#show", as: :pages


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  mount MissionControl::Jobs::Engine, at: "/jobs"
end
