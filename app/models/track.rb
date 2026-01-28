# frozen_string_literal: true

class Track < ApplicationRecord
  belongs_to :playlist, counter_cache: true

  has_one_attached :qr_code_image

  validates :deezer_id, presence: true
  validates :title, presence: true
  validates :artist_name, presence: true
  validates :token, presence: true, uniqueness: true
  validates :position, presence: true

  before_validation :generate_token, on: :create

  scope :ordered, -> { order(:position, :id) }
  scope :with_qr, -> { where(qr_generated: true) }
  scope :without_qr, -> { where(qr_generated: false) }

  searchable_text_column :title
  searchable_text_column :artist_name

  PREVIEW_URL_CACHE_DURATION = 25.minutes

  def display_name
    "#{artist_name} - #{title}"
  end

  def fresh_preview_url
    return preview_url if preview_url_valid?

    refresh_preview_url!
  end

  def preview_url_valid?
    preview_url.present? &&
      preview_url_expires_at.present? &&
      preview_url_expires_at > Time.current
  end

  def refresh_preview_url!
    track_data = Deezer::Client.new.track(deezer_id)
    fresh_url = track_data["preview"]

    update!(
      preview_url: fresh_url,
      preview_url_expires_at: PREVIEW_URL_CACHE_DURATION.from_now
    )

    fresh_url
  end

  def duration_formatted
    return nil unless duration_seconds

    minutes = duration_seconds / 60
    seconds = duration_seconds % 60
    format("%d:%02d", minutes, seconds)
  end

  def mark_qr_generated!
    update!(qr_generated: true)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(8)
  end
end

# == Schema Information
#
# Table name: tracks
#
#  id                                   :bigint           not null, primary key
#  album_cover_url                      :string
#  album_name                           :string
#  artist_name                          :string           not null
#  duration_seconds                     :integer
#  isrc(ISRC information for the track) :string
#  position                             :integer          not null
#  preview_url                          :string
#  preview_url_expires_at               :datetime
#  qr_code_digest                       :string
#  qr_generated                         :boolean          default(FALSE), not null
#  release_year                         :integer
#  title                                :string           not null
#  token                                :string           not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  deezer_album_id                      :string
#  deezer_id                            :string           not null
#  playlist_id                          :bigint           not null
#
# Indexes
#
#  index_tracks_on_deezer_id                 (deezer_id)
#  index_tracks_on_playlist_id               (playlist_id)
#  index_tracks_on_playlist_id_and_position  (playlist_id,position)
#  index_tracks_on_token                     (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (playlist_id => playlists.id)
#
