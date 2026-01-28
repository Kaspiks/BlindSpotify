# frozen_string_literal: true

require "net/http"
require "json"

module Itunes
  class SearchService
    BASE_URL = "https://itunes.apple.com"

    def initialize; end

    # Search for a track and return release year
    def release_year(artist:, title:)
      return nil if artist.blank? || title.blank?

      query = "#{artist} #{title}".gsub(/[^\w\s]/, " ").squeeze(" ").strip
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
  end
end
