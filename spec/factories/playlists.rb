# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    user
    sequence(:name) { |n| "Playlist #{n}" }
    import_status { "pending" }
    tracks_count { 0 }
    imported_tracks_count { 0 }

    trait :with_deezer do
      deezer_id { "123456789" }
      deezer_url { "https://www.deezer.com/playlist/123456789" }
    end

    trait :importing do
      import_status { "importing" }
      tracks_count { 20 }
      imported_tracks_count { 5 }
    end

    trait :completed do
      import_status { "completed" }
      tracks_count { 20 }
      imported_tracks_count { 20 }
    end

    trait :failed do
      import_status { "failed" }
      import_error { "Failed to connect to Deezer API" }
    end

    trait :with_genre do
      genre { ClassificationValue.for_classification("genre").first || association(:classification_value) }
    end
  end
end

# == Schema Information
#
# Table name: playlists
#
#  id                    :bigint           not null, primary key
#  deezer_url            :string
#  description           :text
#  image_url             :string
#  import_error          :text
#  import_status         :string           default("pending"), not null
#  imported_tracks_count :integer          default(0), not null
#  name                  :string           not null
#  tracks_count          :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  deezer_id             :string
#  genre_id              :bigint
#  user_id               :bigint           not null
#
# Indexes
#
#  index_playlists_on_deezer_id      (deezer_id)
#  index_playlists_on_genre_id       (genre_id)
#  index_playlists_on_import_status  (import_status)
#  index_playlists_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (genre_id => classification_values.id)
#  fk_rails_...  (user_id => users.id)
#
