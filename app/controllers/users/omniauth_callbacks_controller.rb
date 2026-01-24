# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: [:spotify, :deezer]

    def deezer
      handle_oauth("Deezer")
    end

    def spotify
      handle_oauth("Spotify")
    end

    def failure
      redirect_to root_path, alert: "Authentication failed: #{failure_message}"
    end

    private

    def handle_oauth(provider_name)
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
      else
        session["devise.oauth_data"] = request.env["omniauth.auth"].except(:extra)
        redirect_to root_path, alert: "Could not authenticate with #{provider_name}. Please try again."
      end
    rescue StandardError => e
      Rails.logger.error "OAuth error for #{provider_name}: #{e.message}"
      redirect_to root_path, alert: "Authentication error: #{e.message}"
    end

    def failure_message
      exception = request.env["omniauth.error"]
      error = request.env["omniauth.error.type"]

      case error
      when :invalid_credentials
        "Invalid credentials"
      when :access_denied
        "Access was denied"
      else
        exception&.message || error.to_s.humanize
      end
    end
  end
end
