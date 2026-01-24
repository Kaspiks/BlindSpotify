# frozen_string_literal: true

# OmniAuth configuration
OmniAuth.config.logger = Rails.logger

# Silence GET request deprecation warnings
OmniAuth.config.allowed_request_methods = [:post]

# In test environment, enable test mode
if Rails.env.test?
  OmniAuth.config.test_mode = true

  # Default mock for Deezer OAuth (currently active provider)
  OmniAuth.config.mock_auth[:deezer] = OmniAuth::AuthHash.new({
    provider: "deezer",
    uid: "test_deezer_123",
    info: {
      email: "test@example.com",
      name: "Test User",
      image: "https://e-cdns-images.dzcdn.net/images/user/test/250x250.jpg"
    },
    credentials: {
      token: "mock_deezer_access_token",
      expires: false
    },
    extra: {
      raw_info: {
        country: "US"
      }
    }
  })

  # Default mock for Spotify OAuth (currently disabled)
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new({
    provider: "spotify",
    uid: "test_spotify_123",
    info: {
      email: "test@example.com",
      name: "Test User",
      image: "https://i.scdn.co/image/test"
    },
    credentials: {
      token: "mock_spotify_access_token",
      refresh_token: "mock_spotify_refresh_token",
      expires_at: 1.hour.from_now.to_i,
      expires: true
    },
    extra: {
      raw_info: {
        product: "premium",
        country: "US"
      }
    }
  })
end
