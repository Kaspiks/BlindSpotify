# frozen_string_literal: true

class AddPreviewUrlExpiresAtToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :preview_url_expires_at, :datetime
  end
end
