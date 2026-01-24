# frozen_string_literal: true

FactoryBot.define do
  factory :track do
    playlist
    sequence(:deezer_id) { |n| "track_#{n}" }
    sequence(:title) { |n| "Track Title #{n}" }
    sequence(:artist_name) { |n| "Artist #{n}" }
    album_name { "Album Name" }
    album_cover_url { "https://e-cdns-images.dzcdn.net/images/cover/test/250x250.jpg" }
    preview_url { "https://cdns-preview-e.dzcdn.net/stream/c-test.mp3" }
    duration_seconds { 180 }
    sequence(:position) { |n| n }
    token { SecureRandom.urlsafe_base64(8) }
    qr_generated { false }

    trait :with_qr do
      qr_generated { true }
    end
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
