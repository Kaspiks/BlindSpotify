# frozen_string_literal: true

require "open-uri"

module Tracks
  # Fetches preview bytes from Deezer/iTunes CDN server-side so we can re-serve them same-origin
  # (avoids browser ORB + CORS issues on <audio>).
  class FetchPreviewBodyService < ApplicationService
    class FetchError < StandardError; end

    def initialize(url:)
      @url = url
    end

    def call
      raise FetchError, "blank url" if url.blank?

      io = URI.open(
        url,
        "User-Agent" => "Mozilla/5.0 (compatible; BlindJam/1.0)",
        open_timeout: 10,
        read_timeout: 45
      )
      ctype = io.content_type if io.respond_to?(:content_type) && io.content_type.present?
      body = io.read
      io.close if io.respond_to?(:close)

      raise FetchError, "empty body" if body.blank?

      ctype = ctype.presence || sniff_type(body, url)
      [body, ctype]
    rescue OpenURI::HTTPError => e
      raise FetchError, "upstream #{e.message}"
    rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise FetchError, e.message
    end

    private

    attr_reader :url

    def sniff_type(body, raw_url)
      return "audio/mp4" if raw_url.to_s.include?(".m4a")

      return "audio/mpeg" if body.start_with?("ID3") || body.byteslice(0, 2) == "\xFF\xFB".b

      "audio/mpeg"
    end
  end
end
