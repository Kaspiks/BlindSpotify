# frozen_string_literal: true

class Game < ApplicationRecord
  belongs_to :user
  belongs_to :playlist

  enum :status, { active: "active", completed: "completed", abandoned: "abandoned" }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }

  before_create :initialize_game

  def current_track
    return nil if track_order.blank? || current_track_index >= track_order.size

    playlist.tracks.find_by(id: track_order[current_track_index])
  end

  def next_track!
    return nil if finished?

    self.current_track_index += 1
    self.tracks_played += 1

    if current_track_index >= track_order.size
      complete!
    else
      save!
    end

    current_track
  end

  def reveal_current!
    self.tracks_revealed += 1
    save!
  end

  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  def abandon!
    update!(status: :abandoned, completed_at: Time.current)
  end

  def finished?
    completed? || abandoned? || current_track_index >= track_order.size
  end

  def progress_percentage
    return 0 if track_order.blank?

    ((current_track_index.to_f / track_order.size) * 100).round
  end

  def total_tracks
    track_order.size
  end

  def tracks_remaining
    [track_order.size - current_track_index, 0].max
  end

  private

  def initialize_game
    self.started_at = Time.current
    self.track_order = playlist.tracks.pluck(:id).shuffle if track_order.blank?
  end
end

# == Schema Information
#
# Table name: games
#
#  id                  :bigint           not null, primary key
#  completed_at        :datetime
#  current_track_index :integer          default(0)
#  started_at          :datetime
#  status              :string           default("active"), not null
#  track_order         :jsonb
#  tracks_played       :integer          default(0)
#  tracks_revealed     :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  playlist_id         :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_games_on_playlist_id  (playlist_id)
#  index_games_on_status       (status)
#  index_games_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (playlist_id => playlists.id)
#  fk_rails_...  (user_id => users.id)
#
