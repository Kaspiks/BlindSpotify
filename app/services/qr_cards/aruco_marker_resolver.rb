# frozen_string_literal: true

require "net/http"
require "tempfile"
require "uri"

module QrCards
  # Resolves ArUco marker ID to a PNG file path for embedding in the PDF.
  # Tries (1) optional remote generator service, (2) pre-generated files in vendor/assets/aruco.
  class ArucoMarkerResolver
    # 0-based marker ID for a track = position - 1 (position is 1-based in DB).
    def self.marker_id_for_track(track)
      (track.position || 1).to_i - 1
    end

    def initialize(generator_url: nil, pregenerated_dir: nil)
      @generator_url = generator_url.presence
      @pregenerated_dir = pregenerated_dir || default_pregenerated_dir
      @temp_paths = {}
    end

    # Returns path to a PNG file (temp file or local path). Caller must not delete.
    # Returns nil if no image is available (caller should fall back to text card).
    def path_for_marker(marker_id)
      return nil if marker_id.negative?

      @temp_paths[marker_id] ||= fetch_or_path(marker_id)
    end

    def cleanup!
      @temp_paths.each_value do |path|
        next unless path
        next unless path.start_with?(Dir.tmpdir.to_s)

        File.delete(path) if File.exist?(path)
      end
      @temp_paths.clear
    end

    private

    def default_pregenerated_dir
      Rails.root.join("vendor", "assets", "aruco").to_s
    end

    def fetch_or_path(marker_id)
      if @generator_url.present?
        path = fetch_from_generator(marker_id)
        return path if path
      end

      local_path = File.join(@pregenerated_dir, "#{marker_id}.png")
      File.exist?(local_path) ? local_path : nil
    end

    def fetch_from_generator(marker_id)
      base = @generator_url.delete_suffix("/")
      url = "#{base}/marker/#{marker_id}.png"
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      f = Tempfile.new(["aruco_#{marker_id}", ".png"])
      f.binmode
      f.write(response.body)
      f.flush
      f.path
    rescue StandardError => e
      Rails.logger.warn "[ArucoMarkerResolver] Failed to fetch #{url}: #{e.message}"
      nil
    end
  end
end
