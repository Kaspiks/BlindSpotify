# frozen_string_literal: true

module Deezer
  class PlaylistImportService < ApplicationService
    def initialize(playlist, on_progress: nil)
      @playlist = playlist
      @on_progress = on_progress # Callback for progress updates
    end

    def call
      return failure("No Deezer ID provided") if @playlist.deezer_id.blank?

      @playlist.start_import!
      notify_progress

      begin
        client = Client.new
        deezer_playlist = client.playlist(@playlist.deezer_id)

        deezer_tracks = client.playlist_tracks(@playlist.deezer_id)

        @playlist.update!(
          name: deezer_playlist["title"],
          image_url: deezer_playlist["picture_medium"],
          description: deezer_playlist["description"].presence,
          tracks_count: deezer_tracks.size
        )
        notify_progress

        import_tracks(deezer_tracks)

        @playlist.complete_import!
        notify_progress

        ::Tracks::EnrichOriginalReleaseYearsJob.perform_later(@playlist.id)

        success(@playlist)
      rescue Client::NotFoundError => e
        @playlist.fail_import!("Playlist not found on Deezer")
        notify_progress
        failure(e.message)
      rescue Client::ApiError => e
        @playlist.fail_import!(e.message)
        notify_progress
        failure(e.message)
      rescue StandardError => e
        Rails.logger.error "Playlist import failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        @playlist.fail_import!(e.message)
        notify_progress
        failure(e.message)
      end
    end

    private

    def import_tracks(deezer_tracks)
      Rails.logger.info "[PlaylistImportService] Importing #{deezer_tracks.size} tracks"

      # Get the next available position (in case we're adding to existing tracks)
      next_position = (@playlist.tracks.maximum(:position) || 0) + 1
      imported_count = 0

      deezer_tracks.each_with_index do |track_data, index|
        next if track_data["id"].blank?

        deezer_id = track_data["id"].to_s

        # Skip if track already exists
        if @playlist.tracks.exists?(deezer_id: deezer_id)
          Rails.logger.debug "[PlaylistImportService] Skipping existing track #{deezer_id}"
          next
        end

        @playlist.tracks.create!(
          deezer_id: deezer_id,
          title: track_data["title"] || "Unknown Title",
          artist_name: track_data.dig("artist", "name") || "Unknown Artist",
          album_name: track_data.dig("album", "title"),
          album_cover_url: track_data.dig("album", "cover_medium"),
          preview_url: track_data["preview"],
          duration_seconds: track_data["duration"],
          isrc: track_data["isrc"],
          position: next_position
        )

        next_position += 1
        imported_count += 1
        @playlist.increment_imported_count!
        Rails.logger.debug "[PlaylistImportService] Imported track #{imported_count}: #{track_data['title']}"

        # Broadcast progress every 5 tracks to avoid overwhelming the channel
        notify_progress if imported_count % 5 == 0 || index == deezer_tracks.size - 1
      end

      Rails.logger.info "[PlaylistImportService] Finished importing, total: #{@playlist.imported_tracks_count}"
    end

    # def extract_year(track_data)
    #   album_id = track_data.dig("album", "id")

    #   album_data = Deezer::Client.new.album(album_id)

    #   binding.pry

    #   release_date = album_data.dig("release_date")
    #   album_year = release_date&.slice(0, 4)
    # end

    def notify_progress
      @on_progress&.call(@playlist)
    end

    def success(playlist)
      Result.new(success: true, playlist: playlist, error: nil)
    end

    def failure(error)
      Result.new(success: false, playlist: @playlist, error: error)
    end

    Result = Struct.new(:success, :playlist, :error, keyword_init: true) do
      def success?
        success
      end

      def failure?
        !success
      end
    end
  end
end
