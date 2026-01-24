class AddDeezerAlbumIdToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :deezer_album_id, :string
  end
end
