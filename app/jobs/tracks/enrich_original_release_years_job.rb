# frozen_string_literal: true

module Tracks
  class EnrichOriginalReleaseYearsJob < ApplicationJob
    queue_as :default

    def perform(playlist_id)
      playlist = Playlist.find(playlist_id)
      Rails.logger.info "[EnrichOriginalReleaseYearsJob] Starting for playlist #{playlist_id}"

      scope = playlist.tracks.where(release_year: nil).order(:id)

      Rails.logger.info "[EnrichOriginalReleaseYearsJob] Found #{scope.count} tracks to enrich"
      
      cache = {}
      enriched_count = 0
      service = Itunes::SearchService.new

      scope.find_each do |track|
        cache_key = "#{track.artist_name}|#{track.title}"
        
        if cache.key?(cache_key)
          year = cache[cache_key]
        else
          year = service.release_year(artist: track.artist_name, title: track.title)
          cache[cache_key] = year
          sleep 0.3
        end

        if year.present?
          track.update!(release_year: year)
          enriched_count += 1
          Rails.logger.info "[EnrichOriginalReleaseYearsJob] Track #{track.id} (#{track.title}): #{year}"
        else
          Rails.logger.info "[EnrichOriginalReleaseYearsJob] Track #{track.id} (#{track.title}): no year found"
        end
      end
      
      Rails.logger.info "[EnrichOriginalReleaseYearsJob] Enriched #{enriched_count} tracks for playlist #{playlist_id}"
    end
  end
end
