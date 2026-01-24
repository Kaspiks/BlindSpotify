# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { "spotify" }
    sequence(:uid) { |n| "spotify_user_#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    admin { false }
    role { nil }
    spotify_access_token { "mock_access_token_#{SecureRandom.hex(16)}" }
    spotify_refresh_token { "mock_refresh_token_#{SecureRandom.hex(16)}" }
    spotify_token_expires_at { 1.hour.from_now }
    spotify_product { "premium" }
    spotify_country { "US" }

    trait :admin do
      admin { true }
    end

    trait :with_role do
      role
    end

    trait :expired_token do
      spotify_token_expires_at { 1.hour.ago }
    end

    trait :expiring_token do
      spotify_token_expires_at { 2.minutes.from_now }
    end

    trait :free_tier do
      spotify_product { "free" }
    end
  end
end
