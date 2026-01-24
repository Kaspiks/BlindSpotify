# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :omniauthable, omniauth_providers: [:spotify]

  belongs_to :role, optional: true

  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, presence: true

  scope :admins, -> { where(admin: true) }
  scope :with_role, ->(role_name) { joins(:role).where(roles: { name: role_name }) }

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
    name.presence || email.presence || "Spotify User"
  end

  def spotify_token_expired?
    return true if spotify_token_expires_at.nil?

    spotify_token_expires_at < Time.current
  end

  def spotify_token_expiring_soon?
    return true if spotify_token_expires_at.nil?

    spotify_token_expires_at < 5.minutes.from_now
  end

  def update_spotify_tokens!(access_token:, refresh_token: nil, expires_at:)
    update!(
      spotify_access_token: access_token,
      spotify_refresh_token: refresh_token || spotify_refresh_token,
      spotify_token_expires_at: expires_at
    )
  end

  class << self
    def from_spotify_omniauth(auth)
      user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      user.assign_attributes(
        email: auth.info.email,
        name: auth.info.name || auth.info.display_name,
        image_url: auth.info.image,
        spotify_access_token: auth.credentials.token,
        spotify_refresh_token: auth.credentials.refresh_token,
        spotify_token_expires_at: Time.at(auth.credentials.expires_at),
        spotify_product: auth.extra&.raw_info&.product,
        spotify_country: auth.extra&.raw_info&.country
      )

      user.save!
      user
    end
  end
end
