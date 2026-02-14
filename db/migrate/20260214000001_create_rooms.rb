# frozen_string_literal: true

class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :code, null: false, index: { unique: true }
      t.references :host, foreign_key: { to_table: :users }, null: true
      t.references :current_track, foreign_key: { to_table: :tracks }, null: true
      t.boolean :revealed, default: false, null: false
      t.string :status, default: "active", null: false

      t.timestamps
    end
  end
end
