# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: [:spotify]

    def spotify
      @user = User.from_spotify_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: "Spotify") if is_navigational_format?
      else
        session["devise.spotify_data"] = request.env["omniauth.auth"].except(:extra)
        redirect_to root_path, alert: "Could not authenticate with Spotify. Please try again."
      end
    end

    def failure
      redirect_to root_path, alert: "Authentication failed: #{failure_message}"
    end

    private

    def failure_message
      exception = request.env["omniauth.error"]
      error = request.env["omniauth.error.type"]

      case error
      when :invalid_credentials
        "Invalid Spotify credentials"
      when :access_denied
        "Access was denied by Spotify"
      else
        exception&.message || error.to_s.humanize
      end
    end
  end
end
