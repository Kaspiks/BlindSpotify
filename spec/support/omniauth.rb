# frozen_string_literal: true

# OmniAuth test helpers
module OmniauthHelpers
  def mock_deezer_auth(options = {})
    OmniAuth.config.mock_auth[:deezer] = OmniAuth::AuthHash.new({
      provider: "deezer",
      uid: options[:uid] || "deezer_user_#{SecureRandom.hex(8)}",
      info: {
        email: options[:email] || "test@example.com",
        name: options[:name] || "Test User",
        image: options[:image] || "https://e-cdns-images.dzcdn.net/images/user/test/250x250.jpg"
      },
      credentials: {
        token: options[:access_token] || "mock_deezer_token_#{SecureRandom.hex(8)}",
        expires: false
      },
      extra: {
        raw_info: {
          country: options[:country] || "US"
        }
      }
    })
  end

  def mock_deezer_auth_failure(error = :access_denied)
    OmniAuth.config.mock_auth[:deezer] = error
  end

  def mock_spotify_auth(options = {})
    OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new({
      provider: "spotify",
      uid: options[:uid] || "spotify_user_#{SecureRandom.hex(8)}",
      info: {
        email: options[:email] || "test@example.com",
        name: options[:name] || "Test User",
        image: options[:image] || "https://i.scdn.co/image/test"
      },
      credentials: {
        token: options[:access_token] || "mock_spotify_token_#{SecureRandom.hex(8)}",
        refresh_token: options[:refresh_token] || "mock_refresh_token_#{SecureRandom.hex(8)}",
        expires_at: (options[:expires_at] || 1.hour.from_now).to_i,
        expires: true
      },
      extra: {
        raw_info: {
          product: options[:product] || "premium",
          country: options[:country] || "US"
        }
      }
    })
  end

  def mock_spotify_auth_failure(error = :access_denied)
    OmniAuth.config.mock_auth[:spotify] = error
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers

  config.before(:each) do
    OmniAuth.config.test_mode = true
  end

  config.after(:each) do
    OmniAuth.config.mock_auth[:deezer] = nil
    OmniAuth.config.mock_auth[:spotify] = nil
  end
end
