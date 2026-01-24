# frozen_string_literal: true

class AddQrGenerationFieldsToPlaylists < ActiveRecord::Migration[8.0]
  def change
    add_column :playlists, :qr_status, :string, default: "pending", null: false
    add_column :playlists, :qr_generated_count, :integer, default: 0, null: false
    add_column :playlists, :qr_error, :text

    add_index :playlists, :qr_status
  end
end
