# frozen_string_literal: true

require "net/http"
require "json"

module MusicBrainz
  class Client
    BASE_URL = "https://musicbrainz.org/ws/2"
    USER_AGENT = "BlindSpotify/1.0 (kaspars@example.com)"
    MAX_RETRIES = 3

    def recording_by_isrc(isrc)
      get(
        "/recording",
        query: "isrc:#{isrc}",
        fmt: "json",
        inc: "releases"
      )
    end

    private

    def get(path, params)
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params)

      retries = 0
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 15
        http.read_timeout = 15
        http.ssl_timeout = 15
        
        # In development, be more lenient with SSL if needed
        if Rails.env.development?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ssl_version = :TLSv1_2
        end
        
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "application/json"

        response = http.request(request)
        JSON.parse(response.body)
      rescue OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn("[MusicBrainz::Client] Retry #{retries}/#{MAX_RETRIES} after #{e.class}: #{e.message}")
          sleep(3 * retries)  # Longer exponential backoff
          retry
        else
          Rails.logger.error("[MusicBrainz::Client] Failed after #{MAX_RETRIES} retries: #{e.class}: #{e.message}")
          raise
        end
      end
    end
  end
end
