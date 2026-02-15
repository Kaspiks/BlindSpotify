# frozen_string_literal: true

class AddUserToRoomParticipants < ActiveRecord::Migration[8.0]
  def change
    change_table :room_participants, bulk: true do |t|
      t.references :participant, foreign_key: { to_table: :users }, null: true
    end
  end
end
