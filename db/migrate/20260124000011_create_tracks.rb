# frozen_string_literal: true

class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.references :playlist, null: false, foreign_key: true

      # Deezer track info
      t.string :deezer_id, null: false
      t.string :title, null: false
      t.string :artist_name, null: false
      t.string :album_name
      t.string :album_cover_url
      t.string :preview_url
      t.integer :duration_seconds
      t.integer :release_year

      # For QR code generation
      t.string :token, null: false
      t.boolean :qr_generated, default: false, null: false

      # Position in playlist
      t.integer :position, null: false

      t.timestamps
    end

    add_index :tracks, :deezer_id
    add_index :tracks, :token, unique: true
    add_index :tracks, [:playlist_id, :position]
  end
end
