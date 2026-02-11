# frozen_string_literal: true

class ArucoDeck < ApplicationRecord
  belongs_to :playlist, optional: true
  has_many :aruco_deck_slots, -> { order(:position) }, dependent: :destroy
  has_many :tracks, through: :aruco_deck_slots

  has_one_attached :qr_cards_pdf

  validates :name, presence: true
  validates :slots_count, numericality: { greater_than: 0 }

  QR_STATUSES = %w[pending generating completed failed].freeze
  validates :qr_status, inclusion: { in: QR_STATUSES }

  def assign_playlist!(playlist)
    new_tracks = playlist.tracks.ordered.limit(slots_count).to_a
    new_slots_count = new_tracks.size

    self.slots_count = new_slots_count
    save!

    new_tracks.each_with_index do |track, i|
      position = i + 1
      slot = aruco_deck_slots.find_or_initialize_by(position: position)
      slot.update!(track: track)
    end

    aruco_deck_slots.where("position > ?", new_slots_count).destroy_all

    update!(playlist: playlist)
  end

  def slot_at(position)
    aruco_deck_slots.find_by(position: position)&.track
  end

  def qr_pending?  = qr_status == "pending"
  def qr_generating? = qr_status == "generating"
  def qr_completed?  = qr_status == "completed"
  def qr_failed?     = qr_status == "failed"

  def start_qr_generation!
    update!(qr_status: "generating", qr_error: nil, qr_generated_count: 0)
  end

  def complete_qr_generation!
    update!(qr_status: "completed", qr_generated_count: aruco_deck_slots.count)
  end

  def fail_qr_generation!(error_message)
    update!(qr_status: "failed", qr_error: error_message)
  end

  def increment_qr_generated_count!
    increment!(:qr_generated_count)
  end

  def qr_progress_percentage
    return 0 if slots_count.zero?
    return 100 if qr_completed?

    ((qr_generated_count.to_f / slots_count) * 100).round
  end

  def can_generate_qr_codes?
    aruco_deck_slots.any?
  end

  def has_slots?
    aruco_deck_slots.exists?
  end
end

# == Schema Information
#
# Table name: aruco_decks
#
#  id                 :bigint           not null, primary key
#  name               :string           not null
#  qr_error           :text
#  qr_generated_count :integer          default(0), not null
#  qr_status          :string           default("pending"), not null
#  slots_count        :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  playlist_id        :bigint
#
# Indexes
#
#  index_aruco_decks_on_playlist_id  (playlist_id)
#
# Foreign Keys
#
#  fk_rails_...  (playlist_id => playlists.id)
#
