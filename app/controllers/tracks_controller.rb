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

  # GET /q/d/:deck_id/:position
  # Resolves dynamic deck slot to track and renders the player directly
  # (no redirect – avoids mobile browser issues with cross-host 302s)
  def play_by_deck_slot
    deck = ArucoDeck.find(params[:deck_id])
    slot = deck.aruco_deck_slots.find_by!(position: params[:position])
    @track = slot.track
    @track.fresh_preview_url
    render :play
  rescue ActiveRecord::RecordNotFound
    render plain: "Track not found", status: :not_found
  rescue Deezer::Client::ApiError => e
    Rails.logger.error "[TracksController#play_by_deck_slot] Deezer API error: #{e.message}"
    render plain: "Unable to load track preview", status: :service_unavailable
  end
end
