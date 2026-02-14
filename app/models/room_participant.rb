# frozen_string_literal: true

class RoomParticipant < ApplicationRecord
  belongs_to :room

  validates :session_id, presence: true
  validates :session_id, uniqueness: { scope: :room_id }
end

# == Schema Information
#
# Table name: room_participants
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  room_id    :bigint           not null
#  session_id :string           not null
#
# Indexes
#
#  index_room_participants_on_room_id                 (room_id)
#  index_room_participants_on_room_id_and_session_id  (room_id,session_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (room_id => rooms.id)
#
