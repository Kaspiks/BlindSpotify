# frozen_string_literal: true

module SpotifyAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :spotify_access_token
  end

  private

  def ensure_fresh_spotify_token
    return unless current_user&.spotify_token_expiring_soon?

    result = Spotify::TokenRefreshService.call(current_user)

    if result.failure?
      Rails.logger.warn "Failed to refresh Spotify token for user #{current_user.id}: #{result.error}"
      # Sign out and redirect to re-authenticate if token refresh fails
      sign_out current_user
      redirect_to root_path, alert: "Your Spotify session expired. Please sign in again."
    end
  end

  def spotify_access_token
    return nil unless current_user

    # Refresh token if needed
    if current_user.spotify_token_expiring_soon?
      result = Spotify::TokenRefreshService.call(current_user)
      return nil if result.failure?
    end

    current_user.spotify_access_token
  end
end
