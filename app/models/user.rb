# frozen_string_literal: true

class User < ApplicationRecord
  # Using database authentication (email/password)
  devise :database_authenticatable, :registerable, :rememberable, :validatable

  belongs_to :role, optional: true
  has_many :playlists, dependent: :destroy
  has_many :games, dependent: :destroy

  # uid/provider only required for OAuth users (optional now)
  validates :uid, uniqueness: { scope: :provider }, allow_nil: true

  scope :admins, -> { where(admin: true) }
  scope :with_role, ->(role_name) { joins(:role).where(roles: { name: role_name }) }
  scope :spotify_users, -> { where(provider: "spotify") }
  scope :deezer_users, -> { where(provider: "deezer") }

  searchable_text_column :email
  searchable_text_column :name

  sortable_by(
    columns: [:email, :name, :created_at],
    defaults: { column: :created_at, direction: :desc }
  )

  def admin?
    admin == true
  end

  def has_permission?(permission_code)
    return true if admin?
    return false unless role

    role.has_permission?(permission_code)
  end

  def role_name
    role&.name || "No Role"
  end

  def display_name
    name.presence || email.presence || "#{provider.titleize} User"
  end

  def spotify?
    provider == "spotify"
  end

  def deezer?
    provider == "deezer"
  end

  # Token expiration checks (works for both providers)
  def access_token_expired?
    return true if token_expires_at.nil?

    token_expires_at < Time.current
  end

  def access_token_expiring_soon?
    return true if token_expires_at.nil?

    token_expires_at < 5.minutes.from_now
  end

  # Unified token fields (aliased from spotify_ fields for backward compatibility)
  def access_token
    spotify_access_token
  end

  def refresh_token
    spotify_refresh_token
  end

  def token_expires_at
    spotify_token_expires_at
  end

  def update_tokens!(access_token:, refresh_token: nil, expires_at:)
    update!(
      spotify_access_token: access_token,
      spotify_refresh_token: refresh_token || self.refresh_token,
      spotify_token_expires_at: expires_at
    )
  end

  # Legacy aliases for Spotify-specific code
  alias_method :spotify_token_expired?, :access_token_expired?
  alias_method :spotify_token_expiring_soon?, :access_token_expiring_soon?

  def update_spotify_tokens!(access_token:, refresh_token: nil, expires_at:)
    update_tokens!(access_token: access_token, refresh_token: refresh_token, expires_at: expires_at)
  end

  class << self
    def from_omniauth(auth)
      case auth.provider
      when "spotify"
        from_spotify_omniauth(auth)
      when "deezer"
        from_deezer_omniauth(auth)
      else
        raise "Unknown provider: #{auth.provider}"
      end
    end

    def from_spotify_omniauth(auth)
      user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      user.assign_attributes(
        email: auth.info.email,
        name: auth.info.name || auth.info.display_name,
        image_url: auth.info.image,
        spotify_access_token: auth.credentials.token,
        spotify_refresh_token: auth.credentials.refresh_token,
        spotify_token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        spotify_product: auth.extra&.raw_info&.product,
        spotify_country: auth.extra&.raw_info&.country
      )

      user.save!
      user
    end

    def from_deezer_omniauth(auth)
      user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      user.assign_attributes(
        email: auth.info.email,
        name: auth.info.name,
        image_url: auth.info.image,
        spotify_access_token: auth.credentials.token, # Reusing field for Deezer token
        spotify_refresh_token: nil, # Deezer tokens don't expire/refresh the same way
        spotify_token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        spotify_product: nil,
        spotify_country: auth.extra&.raw_info&.country
      )

      user.save!
      user
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
