# frozen_string_literal: true

require "net/http"
require "json"

module Deezer
  class Client
    BASE_URL = "https://api.deezer.com"

    class ApiError < StandardError; end
    class NotFoundError < ApiError; end
    class RateLimitError < ApiError; end

    def initialize(access_token: nil)
      @access_token = access_token
    end

    # Fetch playlist info by ID
    def playlist(playlist_id)
      response = get("/playlist/#{playlist_id}")
      raise NotFoundError, "Playlist not found" if response["error"]

      response
    end

    # Fetch all tracks from a playlist (handles pagination)
    def playlist_tracks(playlist_id, limit: 100)
      tracks = []
      index = 0

      loop do
        Rails.logger.debug "[Deezer::Client] Fetching tracks at index #{index} with limit #{limit}"
        response = get("/playlist/#{playlist_id}/tracks", { index: index, limit: limit })
        break if response["error"]

        data = response["data"] || []
        Rails.logger.debug "[Deezer::Client] Got #{data.size} tracks, total in response: #{response['total']}"
        break if data.empty?

        tracks.concat(data)

        # Deezer returns 'total' for the total number of tracks
        total = response["total"].to_i
        Rails.logger.debug "[Deezer::Client] Total tracks so far: #{tracks.size}/#{total}"
        break if tracks.size >= total || total.zero?

        # Move to next page
        index += data.size
      end

      Rails.logger.info "[Deezer::Client] Fetched #{tracks.size} total tracks"
      tracks
    end

    # Search for playlists
    def search_playlists(query, limit: 25)
      response = get("/search/playlist", q: query, limit: limit)
      response["data"] || []
    end

    def album(album_id)
      response = get("/album/#{album_id}")
      raise NotFoundError, "Album not found" if response["error"]

      response
    end

    # Fetch a single track by ID
    def track(track_id)
      response = get("/track/#{track_id}")
      raise NotFoundError, "Track not found" if response["error"]

      response
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      params[:access_token] = @access_token if @access_token
      uri.query = URI.encode_www_form(params) if params.any?

      response = Net::HTTP.get_response(uri)

      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 404
        raise NotFoundError, "Resource not found"
      else
        raise ApiError, "API error: #{response.code} - #{response.body}"
      end
    end
  end
end
