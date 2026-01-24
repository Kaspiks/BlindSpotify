# frozen_string_literal: true

module Deezer
  class AlbumReleaseYearService
    def initialize(client: Client.new)
      @client = client
    end

    def call(album_id)
      return nil if album_id.blank?

      album_data = @client.album(album_id)
      release_date = album_data["release_date"]
      
      return nil if release_date.blank?
      
      # Release date format is "YYYY-MM-DD"
      year = release_date[0, 4].to_i
      year.positive? ? year : nil
    rescue Client::NotFoundError, Client::ApiError => e
      Rails.logger.warn("[Deezer::AlbumReleaseYearService] Failed for album #{album_id}: #{e.message}")
      nil
    end
  end
end
