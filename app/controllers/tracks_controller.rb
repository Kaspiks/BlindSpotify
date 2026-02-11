# frozen_string_literal: true

class TracksController < ApplicationController
  skip_before_action :authenticate_user!
  layout "player"

  # GET /q/:token
  # Shows a player page for QR code scans (preview URL refreshed in background via JS when expired)
  def play
    @track = Track.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render plain: "Track not found", status: :not_found
  end

  # GET /q/d/:deck_id/:position
  # Resolves dynamic deck slot to track and renders the player directly
  # (no redirect – avoids mobile browser issues with cross-host 302s)
  def play_by_deck_slot
    deck = ArucoDeck.find(params[:deck_id])
    slot = deck.aruco_deck_slots.find_by!(position: params[:position])
    @track = slot.track
    render :play
  rescue ActiveRecord::RecordNotFound
    render plain: "Track not found", status: :not_found
  end

  def refresh_preview
    @track = Track.find_by!(token: params[:token])
    head :not_found and return unless @track

    url = @track.fresh_preview_url
    render json: { preview_url: url }
  rescue Deezer::Client::ApiError => e
    Rails.logger.error "[TracksController#refresh_preview] Deezer API error: #{e.message}"
    render json: { error: "Unable to load preview" }, status: :service_unavailable
  end
end
