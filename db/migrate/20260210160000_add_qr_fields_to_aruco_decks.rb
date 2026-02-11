# frozen_string_literal: true

class AddQrFieldsToArucoDecks < ActiveRecord::Migration[8.0]
  def change
    change_table :aruco_decks do |t|
      t.string :qr_status, default: "pending", null: false
      t.integer :qr_generated_count, default: 0, null: false
      t.text :qr_error
    end
  end
end
