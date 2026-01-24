# frozen_string_literal: true

class QrCodesGenerationJob < ApplicationJob
  queue_as :default

  def perform(playlist_id)
    playlist = Playlist.find(playlist_id)
    Rails.logger.info "[QrCodesGenerationJob] Starting QR generation for playlist #{playlist_id}"

    result = QrCards::GeneratorService.new(
      playlist,
      on_progress: ->(p) { broadcast_progress(p) }
    ).call

    if result.success?
      Rails.logger.info "[QrCodesGenerationJob] QR generation completed for playlist #{playlist_id}"
    else
      Rails.logger.error "[QrCodesGenerationJob] QR generation failed for playlist #{playlist_id}: #{result.error}"
    end
  end

  private

  def broadcast_progress(playlist)
    Rails.logger.debug "[QrCodesGenerationJob] Broadcasting progress: #{playlist.qr_generated_count}/#{playlist.tracks_count}"

    # Broadcast progress update via Turbo Stream
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_playlist_#{playlist.id}",
      target: "playlist_#{playlist.id}_qr_progress",
      partial: "admin/playlists/qr_progress",
      locals: { playlist: playlist }
    )
  end
end
