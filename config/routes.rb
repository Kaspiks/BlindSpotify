# frozen_string_literal: true

Rails.application.routes.draw do
  # Development-only login bypass (when OAuth providers unavailable)
  if Rails.env.development?
    get "dev/login", to: "dev_sessions#new", as: :dev_login
    post "dev/login", to: "dev_sessions#create", as: :dev_sessions
  end

  # Standard Devise routes for email/password authentication
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Admin namespace for curator/admin functionality
  namespace :admin do
    root "dashboard#index"
    resources :users, only: [:index, :show, :edit, :update, :destroy]
    resources :roles
    resources :settings, only: [:index, :edit, :update]

    # Classifications management
    resources :classification_items, only: [:index]
    resources :classifications, only: [:show] do
      resources :classification_values, only: [:new, :create, :edit, :update]
    end

    # Playlist QR code management
    resources :playlists, only: [:index, :show] do
      member do
        post :generate_qr_codes
        get :download_cards
        get :qr_status
      end

      resources :tracks, only: [] do
        member do
          get :qr_code
        end
      end
    end
  end

  # Playlists
  resources :playlists, only: [:index, :show, :new, :create, :destroy] do
    member do
      post :import
      get :status
    end
  end

  # Game mode - blind track guessing
  resources :games, only: [:index, :new, :create, :show] do
    member do
      post :next_track
      post :reveal
      patch :abandon
    end
  end

  # Track playback via QR code token
  get "q/:token", to: "tracks#play", as: :track_qr

  # Health check for deployment
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
