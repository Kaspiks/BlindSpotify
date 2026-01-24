# frozen_string_literal: true

class Track < ApplicationRecord
  belongs_to :playlist, counter_cache: true

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

  def display_name
    "#{artist_name} - #{title}"
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
