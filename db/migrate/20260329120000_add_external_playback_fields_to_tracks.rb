# frozen_string_literal: true

class AddExternalPlaybackFieldsToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :spotify_uri, :string
    add_column :tracks, :external_web_url, :string
  end
end
