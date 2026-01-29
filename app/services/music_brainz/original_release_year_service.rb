# frozen_string_literal: true

module MusicBrainz
  class OriginalReleaseYearService
    def initialize(client: Client.new)
      @client = client
    end

    def call(isrc)
      return nil if isrc.blank?

      normalized_isrc = isrc.to_s.strip.upcase.gsub(/\W/, "")
      return nil if normalized_isrc.length != 12

      data = @client.recording_by_isrc(normalized_isrc)
      recordings = data["recordings"] || []
      return nil if recordings.empty?

      # Prefer MusicBrainz's computed first-release-date (most reliable)
      year_from_first_release_date = recordings
        .filter_map { |r| r["first-release-date"].to_s[/^\d{4}/] }
        .map(&:to_i)
        .min
      return year_from_first_release_date if year_from_first_release_date

      # Fallback: derive from official releases with dates
      releases = recordings.flat_map { |r| r["releases"] || [] }
      releases = releases.select do |r|
        r["status"] == "Official" && r["date"].to_s.match?(/^\d{4}/)
      end
      return nil if releases.empty?

      releases.min_by { |r| r["date"] }["date"][0, 4].to_i
    rescue OpenSSL::SSL::SSLError, EOFError, Net::ReadTimeout => e
      Rails.logger.warn "[MusicBrainz] Request failed: #{e.class} - #{e.message}" if Rails.env.development?
      nil
    end
  end
end
