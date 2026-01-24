# frozen_string_literal: true

class TracksController < ApplicationController
  skip_before_action :authenticate_user!
  layout "player"

  # GET /q/:token
  # Shows a player page for QR code scans
  def play
    @track = Track.find_by!(token: params[:token])
    # Refresh preview URL if needed
    @track.fresh_preview_url
  rescue ActiveRecord::RecordNotFound
    render plain: "Track not found", status: :not_found
  rescue Deezer::Client::ApiError => e
    Rails.logger.error "[TracksController#play] Deezer API error: #{e.message}"
    render plain: "Unable to load track preview", status: :service_unavailable
  end
end
