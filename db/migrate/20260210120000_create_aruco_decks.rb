# frozen_string_literal: true

class CreateArucoDecks < ActiveRecord::Migration[8.0]
  def change
    create_table :aruco_decks do |t|
      t.references :playlist, null: true, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :slots_count, null: false, default: 0

      t.timestamps
    end

    create_table :aruco_deck_slots do |t|
      t.references :aruco_deck, null: false, foreign_key: true, index: true
      t.integer :position, null: false
      t.references :track, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :aruco_deck_slots, [:aruco_deck_id, :position], unique: true
  end
end
