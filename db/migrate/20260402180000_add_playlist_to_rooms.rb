# frozen_string_literal: true

class AddPlaylistToRooms < ActiveRecord::Migration[8.0]
  def change
    add_reference :rooms, :playlist, null: true, foreign_key: true
  end
end
