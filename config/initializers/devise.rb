# frozen_string_literal: true

# Devise configuration with OAuth providers

Devise.setup do |config|
  require "devise/orm/active_record"

  # Session and remember me
  config.remember_for = 2.weeks
  config.expire_all_remember_me_on_sign_out = true

  # General settings
  config.default_scope = :user
  config.sign_out_all_scopes = true
  config.navigational_formats = ["*/*", :html, :turbo_stream]
  config.sign_out_via = :delete

  # ==> OmniAuth Providers

  # --- Deezer OAuth (Currently Active) ---
  # Credentials should be set via Rails credentials or environment variables:
  #   DEEZER_APP_ID
  #   DEEZER_APP_SECRET
  #
  # Get credentials from: https://developers.deezer.com/myapps
  #
  # Scopes:
  #   - basic_access: Access basic info
  #   - email: Access email address
  #   - offline_access: Access data anytime (refresh token)
  #   - manage_library: Manage user's library
  #   - listening_history: Access listening history
  config.omniauth :deezer,
    Rails.application.credentials.dig(:deezer, :app_id) || ENV["DEEZER_APP_ID"],
    Rails.application.credentials.dig(:deezer, :app_secret) || ENV["DEEZER_APP_SECRET"],
    perms: "basic_access,email,offline_access,manage_library,listening_history"

  # --- Spotify OAuth (Currently Disabled) ---
  # Uncomment when Spotify API is available
  # Credentials should be set via Rails credentials or environment variables:
  #   SPOTIFY_CLIENT_ID
  #   SPOTIFY_CLIENT_SECRET
  #
  # Get credentials from: https://developer.spotify.com/dashboard
  #
  # Required scopes for full functionality:
  #   - user-read-email: Access email address
  #   - user-read-private: Access subscription level and country
  #   - playlist-read-private: Read private playlists
  #   - playlist-read-collaborative: Read collaborative playlists
  #   - streaming: Control playback (Web Playback SDK)
  #   - user-modify-playback-state: Control playback on devices
  #   - user-read-playback-state: Read playback state
  #
  # config.omniauth :spotify,
  #   Rails.application.credentials.dig(:spotify, :client_id) || ENV["SPOTIFY_CLIENT_ID"],
  #   Rails.application.credentials.dig(:spotify, :client_secret) || ENV["SPOTIFY_CLIENT_SECRET"],
  #   scope: %w[
  #     user-read-email
  #     user-read-private
  #     playlist-read-private
  #     playlist-read-collaborative
  #     streaming
  #     user-modify-playback-state
  #     user-read-playback-state
  #   ].join(" ")
end
