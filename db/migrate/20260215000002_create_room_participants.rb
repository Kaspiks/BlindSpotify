# frozen_string_literal: true

class CreateRoomParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :room_participants do |t|
      t.references :room, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :name

      t.timestamps
    end

    add_index :room_participants, [:room_id, :session_id], unique: true
  end
end
