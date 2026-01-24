# frozen_string_literal: true

Rails.application.routes.draw do
  # Spotify OAuth via Devise
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
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

    # TODO: Add playlist management routes
    # resources :playlists do
    #   resources :tracks, only: [:index]
    #   member do
    #     post :generate_qr_codes
    #   end
    # end
  end

  # Health check for deployment
  get "up" => "rails/health#show", as: :rails_health_check

  # Placeholder routes for the new project
  # resources :playlists, only: [:index, :show, :new, :create]
  # get "q/:token", to: "tracks#play", as: :track_qr

  root "home#index"
end
