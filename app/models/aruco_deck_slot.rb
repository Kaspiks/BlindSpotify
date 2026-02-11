# frozen_string_literal: true

class ArucoDeckSlot < ApplicationRecord
  belongs_to :aruco_deck
  belongs_to :track

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :position, uniqueness: { scope: :aruco_deck_id }
end

# == Schema Information
#
# Table name: aruco_deck_slots
#
#  id            :bigint           not null, primary key
#  position      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  aruco_deck_id :bigint           not null
#  track_id      :bigint           not null
#
# Indexes
#
#  index_aruco_deck_slots_on_aruco_deck_id               (aruco_deck_id)
#  index_aruco_deck_slots_on_aruco_deck_id_and_position  (aruco_deck_id,position) UNIQUE
#  index_aruco_deck_slots_on_track_id                    (track_id)
#
# Foreign Keys
#
#  fk_rails_...  (aruco_deck_id => aruco_decks.id)
#  fk_rails_...  (track_id => tracks.id)
#
