# frozen_string_literal: true

require "open3"

module Tracks
  # POST /q/:token/deck_scan
  class DeckScanActionsController < ApplicationController
    skip_before_action :authenticate_user!

    def create
      track = Track.find_by!(token: params[:token])
      playlist = track.playlist

      image = params[:image] || params[:photo]
      unless image.respond_to?(:tempfile) && image.tempfile.present?
        return render json: { tracks: [], error: "No image provided" }, status: :unprocessable_entity
      end

      path = image.tempfile.path
      marker_ids = run_aruco_detection(path)

      positions = marker_ids.map { |id| id + 1 }.uniq
      tracks = playlist.tracks.ordered.where(position: positions).map do |t|
        {
          position: t.position,
          title: t.title,
          artist_name: t.artist_name,
          release_year: t.release_year
        }
      end

      render json: { tracks: tracks }
    rescue ActiveRecord::RecordNotFound
      render json: { tracks: [], error: "Track not found" }, status: :not_found
    end

    private

    def run_aruco_detection(image_path)
      script = Rails.root.join("scripts", "aruco", "detect_markers.py")
      return [] unless File.exist?(script)

      out, _err, status = Open3.capture3("python3", script.to_s, image_path.to_s)
      return [] unless status.success?

      out.strip.split("\n").map(&:strip).reject(&:blank?).map(&:to_i).uniq
    rescue StandardError => e
      Rails.logger.warn "[Tracks::DeckScanActionsController] ArUco detection failed: #{e.message}"
      []
    end
  end
end
