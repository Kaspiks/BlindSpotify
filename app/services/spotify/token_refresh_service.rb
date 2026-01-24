# frozen_string_literal: true

module Spotify
  class TokenRefreshService < ApplicationService
    SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"

    def initialize(user)
      @user = user
    end

    def call
      return success_result(@user) unless @user.spotify_token_expiring_soon?
      return failure_result("No refresh token available") if @user.spotify_refresh_token.blank?

      refresh_token
    end

    private

    def refresh_token
      response = Net::HTTP.post_form(
        URI(SPOTIFY_TOKEN_URL),
        {
          grant_type: "refresh_token",
          refresh_token: @user.spotify_refresh_token,
          client_id: spotify_client_id,
          client_secret: spotify_client_secret
        }
      )

      handle_response(response)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        data = JSON.parse(response.body)
        @user.update_spotify_tokens!(
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          expires_at: Time.current + data["expires_in"].to_i.seconds
        )
        success_result(@user)
      else
        error_data = JSON.parse(response.body) rescue {}
        failure_result(error_data["error_description"] || "Token refresh failed")
      end
    end

    def spotify_client_id
      Rails.application.credentials.dig(:spotify, :client_id) || ENV["SPOTIFY_CLIENT_ID"]
    end

    def spotify_client_secret
      Rails.application.credentials.dig(:spotify, :client_secret) || ENV["SPOTIFY_CLIENT_SECRET"]
    end

    def success_result(user)
      Result.new(success: true, user: user, error: nil)
    end

    def failure_result(error)
      Result.new(success: false, user: nil, error: error)
    end

    Result = Struct.new(:success, :user, :error, keyword_init: true) do
      def success?
        success
      end

      def failure?
        !success
      end
    end
  end
end
