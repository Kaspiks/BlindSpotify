# frozen_string_literal: true

class PlaylistImportJob < ApplicationJob
  queue_as :default

  def perform(playlist_id)
    playlist = Playlist.find(playlist_id)
    Rails.logger.info "[PlaylistImportJob] Starting import for playlist #{playlist_id}"

    result = Deezer::PlaylistImportService.new(
      playlist,
      on_progress: ->(p) { broadcast_progress(p) }
    ).call

    if result.success?
      Rails.logger.info "[PlaylistImportJob] Import completed for playlist #{playlist_id}"
      broadcast_tracks_list(playlist.reload)
    else
      Rails.logger.error "[PlaylistImportJob] Import failed for playlist #{playlist_id}: #{result.error}"
    end
  end

  private

  def broadcast_progress(playlist)
    Rails.logger.debug "[PlaylistImportJob] Broadcasting progress: #{playlist.imported_tracks_count}/#{playlist.tracks_count}"

    # Broadcast progress update via Turbo Stream
    Turbo::StreamsChannel.broadcast_replace_to(
      "playlist_#{playlist.id}",
      target: "playlist_#{playlist.id}_progress",
      partial: "playlists/progress",
      locals: { playlist: playlist }
    )

    # Also broadcast to the playlists list if visible
    Turbo::StreamsChannel.broadcast_replace_to(
      "playlists",
      target: "playlist_#{playlist.id}",
      partial: "playlists/playlist",
      locals: { playlist: playlist }
    )
  end

  def broadcast_tracks_list(playlist)
    # Broadcast updated tracks list when import completes
    Turbo::StreamsChannel.broadcast_replace_to(
      "playlist_#{playlist.id}",
      target: "playlist_#{playlist.id}_tracks",
      partial: "playlists/tracks_list",
      locals: { playlist: playlist, tracks: playlist.tracks.ordered }
    )
  end
end
