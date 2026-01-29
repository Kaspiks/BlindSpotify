# frozen_string_literal: true

module Tracks
  class EnrichOriginalReleaseYearsJob < ApplicationJob
    queue_as :default

    MUSICBRAINZ_DELAY = 2.0
    MUSICBRAINZ_RETRY_DELAY = 3.0
    ITUNES_DELAY = 0.3

    def perform(playlist_id)
      playlist = Playlist.find(playlist_id)

      scope = playlist.tracks.where(release_year: nil).order(:id)
      return if scope.empty?

      @musicbrainz = MusicBrainz::OriginalReleaseYearService.new
      @itunes = Itunes::SearchService.new
      @cache = {}

      scope.find_each do |track|
        year = find_release_year(track)
        track.update!(release_year: year) if year.present?
      end
    end

    private

    def find_release_year(track)
      cache_key = "#{track.artist_name}|#{track.title}"
      return @cache[cache_key] if @cache.key?(cache_key)

      year = musicbrainz_lookup(track.isrc) if track.isrc.present?

      year ||= itunes_lookup(track.artist_name, track.title)

      @cache[cache_key] = year
      year
    end

    def musicbrainz_lookup(isrc)
      year = @musicbrainz.call(isrc)
      if year.nil?
        sleep MUSICBRAINZ_RETRY_DELAY 
        year = @musicbrainz.call(isrc)
      end
      sleep MUSICBRAINZ_DELAY 
      year
    rescue StandardError
      nil
    end

    def itunes_lookup(artist, title)
      year = @itunes.release_year(artist: artist, title: title)
      sleep ITUNES_DELAY
      year
    rescue StandardError
      nil
    end
  end
end
