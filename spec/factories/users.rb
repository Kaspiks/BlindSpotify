# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { "deezer" }
    sequence(:uid) { |n| "deezer_user_#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    admin { false }
    role { nil }
    spotify_access_token { "mock_access_token_#{SecureRandom.hex(16)}" }
    spotify_refresh_token { nil }
    spotify_token_expires_at { nil }
    spotify_product { nil }
    spotify_country { "US" }

    trait :admin do
      admin { true }
    end

    trait :with_role do
      role
    end

    trait :deezer do
      provider { "deezer" }
      sequence(:uid) { |n| "deezer_user_#{n}" }
    end

    trait :spotify do
      provider { "spotify" }
      sequence(:uid) { |n| "spotify_user_#{n}" }
      spotify_refresh_token { "mock_refresh_token_#{SecureRandom.hex(16)}" }
      spotify_token_expires_at { 1.hour.from_now }
      spotify_product { "premium" }
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

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  admin                    :boolean          default(FALSE), not null
#  email                    :string
#  encrypted_password       :string
#  image_url                :string
#  name                     :string
#  provider                 :string
#  remember_created_at      :datetime
#  spotify_access_token     :text
#  spotify_country          :string
#  spotify_product          :string
#  spotify_refresh_token    :text
#  spotify_token_expires_at :datetime
#  uid                      :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  role_id                  :bigint
#
# Indexes
#
#  index_users_on_email             (email) UNIQUE
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#  index_users_on_role_id           (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#
