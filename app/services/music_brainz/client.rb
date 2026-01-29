# frozen_string_literal: true

require "net/http"
require "json"

module MusicBrainz
  class Client
    BASE_URL = "https://musicbrainz.org/ws/2"
    USER_AGENT = "HitsterClone/1.0.0 ( kaspars@example.com )"
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
      loop do
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 15
          http.read_timeout = 15
          http.ssl_timeout = 15

          if Rails.env.development?
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.ssl_version = :TLSv1_2
            # In Docker, SSL can be flaky; set MUSICBRAINZ_SSL_VERIFY=none to disable (dev only)
            if ENV["MUSICBRAINZ_SSL_VERIFY"] == "none"
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
          end

          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = USER_AGENT
          request["Accept"] = "application/json"

          response = http.request(request)

          # Retry on rate limit (503) with backoff
          if response.is_a?(Net::HTTPServiceUnavailable) && retries < MAX_RETRIES
            retries += 1
            sleep(1 + retries)
            next
          end

          unless response.is_a?(Net::HTTPSuccess)
            if Rails.env.development?
              msg = "[MusicBrainz] Non-success response: #{response.code} #{response.message}"
              Rails.logger.warn(msg)
              puts msg
            end
            return { "recordings" => [] }
          end

          return JSON.parse(response.body)
        rescue OpenSSL::SSL::SSLError, EOFError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET
          retries += 1
          if retries <= MAX_RETRIES
            sleep(3 * retries)
            retry
          else
            raise
          end
        end
      end
    end
  end
end
