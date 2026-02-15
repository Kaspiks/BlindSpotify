# frozen_string_literal: true

class AddStateJsonToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :state_json, :jsonb, default: {}, null: false
  end
end
