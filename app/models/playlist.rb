# frozen_string_literal: true

class Playlist < ApplicationRecord
  belongs_to :user
  belongs_to :genre, class_name: "ClassificationValue", optional: true
  has_many :tracks, dependent: :destroy

  validates :name, presence: true

  # Import statuses
  IMPORT_STATUSES = %w[pending importing completed failed].freeze
  validates :import_status, inclusion: { in: IMPORT_STATUSES }

  scope :pending, -> { where(import_status: "pending") }
  scope :importing, -> { where(import_status: "importing") }
  scope :completed, -> { where(import_status: "completed") }
  scope :failed, -> { where(import_status: "failed") }

  searchable_text_column :name

  sortable_by(
    columns: [:name, :tracks_count, :created_at],
    defaults: { column: :created_at, direction: :desc }
  )

  def import_progress_percentage
    return 0 if tracks_count.zero?
    return 100 if import_status == "completed"

    ((imported_tracks_count.to_f / tracks_count) * 100).round
  end

  def pending?
    import_status == "pending"
  end

  def importing?
    import_status == "importing"
  end

  def completed?
    import_status == "completed"
  end

  def failed?
    import_status == "failed"
  end

  def start_import!
    update!(import_status: "importing", import_error: nil)
  end

  def complete_import!
    update!(import_status: "completed", imported_tracks_count: tracks.count)
  end

  def fail_import!(error_message)
    update!(import_status: "failed", import_error: error_message)
  end

  def increment_imported_count!
    increment!(:imported_tracks_count)
  end

  # Extract Deezer playlist ID from URL or ID string
  def self.extract_deezer_id(input)
    return nil if input.blank?

    # Handle full URLs like https://www.deezer.com/playlist/1234567890
    if input.include?("deezer.com")
      match = input.match(%r{/playlist/(\d+)})
      return match[1] if match
    end

    # Handle just the ID
    input.strip if input.match?(/^\d+$/)
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
