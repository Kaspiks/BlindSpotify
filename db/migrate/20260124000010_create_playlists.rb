# frozen_string_literal: true

class CreatePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists do |t|
      t.string :name, null: false
      t.string :deezer_id
      t.string :deezer_url
      t.string :image_url
      t.text :description
      t.integer :tracks_count, default: 0, null: false
      t.integer :imported_tracks_count, default: 0, null: false
      t.string :import_status, default: "pending", null: false
      t.text :import_error

      t.references :user, null: false, foreign_key: true
      t.references :genre, foreign_key: { to_table: :classification_values }

      t.timestamps
    end

    add_index :playlists, :deezer_id
    add_index :playlists, :import_status
  end
end
