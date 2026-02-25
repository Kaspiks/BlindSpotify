# frozen_string_literal: true

require "net/http"
require "json"

module Itunes
  class SearchService
    BASE_URL = "https://itunes.apple.com"

    PREVIEW_COUNTRIES = ENV.fetch("ITUNES_PREVIEW_COUNTRIES", "RU,US,LV").split(",").map(&:strip).freeze

    def initialize(country: "US")
      @country = country
    end

    def preview_url(artist:, title:)
      return nil if artist.blank? || title.blank?

      query = build_search_query(artist, title)

      PREVIEW_COUNTRIES.each do |country|
        url = fetch_preview_for_country(query: query, country: country)
        return url if url.present?
      end

      nil
    rescue JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET
      nil
    end

    # Search for a track and return release year
    def release_year(artist:, title:)
      return nil if artist.blank? || title.blank?

      query = build_search_query(artist, title)
      uri = URI("#{BASE_URL}/search")
      uri.query = URI.encode_www_form(
        term: query,
        entity: "song",
        limit: 5
      )

      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      results = data["results"] || []

      # Find best match - iTunes returns releaseDate in ISO format
      results.each do |result|
        release_date = result["releaseDate"]
        next if release_date.blank?

        # releaseDate format: "2002-10-28T07:00:00Z"
        year = release_date[0, 4].to_i
        return year if year.positive?
      end

      nil
    rescue JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET
      nil
    end

    private

    def fetch_preview_for_country(query:, country:)
      uri = URI("#{BASE_URL}/search")
      uri.query = URI.encode_www_form(
        term: query,
        media: "music",
        entity: "musicTrack",
        limit: 5,
        country: country
      )

      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      results = data["results"] || []

      results.each do |result|
        next if result["kind"] == "music-video"
        next if result["previewUrl"].blank?

        return result["previewUrl"]
      end

      nil
    rescue JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET
      nil
    end

    def build_search_query(artist, title)
      "#{artist} #{title}".gsub(/[^\w\s]/, " ").squeeze(" ").strip
    end
  end
end
