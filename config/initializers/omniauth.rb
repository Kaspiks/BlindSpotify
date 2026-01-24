# frozen_string_literal: true

# OmniAuth configuration
OmniAuth.config.logger = Rails.logger

# Silence GET request deprecation warnings
OmniAuth.config.allowed_request_methods = [:post]

# In test environment, enable test mode
if Rails.env.test?
  OmniAuth.config.test_mode = true

  # Default mock for Spotify OAuth
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new({
    provider: "spotify",
    uid: "test_user_123",
    info: {
      email: "test@example.com",
      name: "Test User",
      image: "https://i.scdn.co/image/test"
    },
    credentials: {
      token: "mock_access_token",
      refresh_token: "mock_refresh_token",
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
