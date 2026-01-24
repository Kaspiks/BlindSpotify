# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.string :status, null: false, default: "active" # active, completed, abandoned
      t.integer :current_track_index, default: 0
      t.integer :tracks_played, default: 0
      t.integer :tracks_revealed, default: 0
      t.jsonb :track_order, default: [] # Shuffled track IDs
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :games, :status
  end
end
