# frozen_string_literal: true

# Development-only controller for bypassing OAuth
# This allows testing the app without real Deezer/Spotify credentials
class DevSessionsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :ensure_development_environment

  def new
    @users = User.order(:email)
  end

  def create
    if params[:user_id].present?
      user = User.find(params[:user_id])
    else
      # Create a new dev user
      user = User.find_or_create_by!(provider: "deezer", uid: "dev_#{SecureRandom.hex(8)}") do |u|
        u.email = params[:email].presence || "dev_#{SecureRandom.hex(4)}@example.com"
        u.name = params[:name].presence || "Dev User"
        u.spotify_access_token = "dev_token_#{SecureRandom.hex(16)}"
        u.spotify_country = "US"
      end
    end

    sign_in(user)
    redirect_to root_path, notice: "Signed in as #{user.display_name} (Development Mode)"
  end

  private

  def ensure_development_environment
    unless Rails.env.development?
      redirect_to root_path, alert: "Dev login is only available in development"
    end
  end
end
