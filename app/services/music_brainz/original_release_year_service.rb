# frozen_string_literal: true

module MusicBrainz
  class OriginalReleaseYearService
    def initialize(client: Client.new)
      @client = client
    end

    def call(isrc)
      return nil if isrc.blank?

      data = @client.recording_by_isrc(isrc)
      recordings = data["recordings"] || []
      return nil if recordings.empty?

      releases = recordings.flat_map { |r| r["releases"] || [] }

      releases = releases.select do |r|
        r["status"] == "Official" && r["date"].to_s.match?(/^\d{4}/)
      end

      return nil if releases.empty?

      releases.min_by { |r| r["date"] }["date"][0, 4].to_i
    rescue OpenSSL::SSL::SSLError, EOFError, Net::ReadTimeout
      nil
    end
  end
end
