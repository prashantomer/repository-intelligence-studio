require 'sidekiq/web'

Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Sidekiq Web UI for monitoring background jobs
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == "admin" && password == "sidekiq"
  end
  mount Sidekiq::Web => '/sidekiq'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "repositories#index"
  resource :settings, only: %i[edit update]

  resources :repositories, only: %i[index new create show edit update] do
    post :resync, on: :member
    get :search, on: :member
    get :assistant, on: :member
    post :ask, on: :member
  end
end
