# frozen_string_literal: true

class TracksController < ApplicationController
  skip_before_action :authenticate_user!
  layout "player"

  # GET /q/:token
  # Shows a player page for QR code scans (preview URL refreshed in background via JS when expired).
  # If user is logged in and hosting a room (session), plays the track in that room and redirects to the room.
  def play
    @track = Track.find_by!(token: params[:token])
    return if play_in_host_room_if_applicable

    render :play
  rescue ActiveRecord::RecordNotFound
    render plain: "Track not found", status: :not_found
  end

  # GET /q/d/:deck_id/:position
  # Resolves dynamic deck slot to track. If user is hosting a room, plays in room and redirects; else renders player.
  def play_by_deck_slot
    deck = ArucoDeck.find(params[:deck_id])
    slot = deck.aruco_deck_slots.find_by!(position: params[:position])
    @track = slot.track
    return if play_in_host_room_if_applicable

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

  private

  # If user is logged in and has an active host room in session, play this track in that room and redirect.
  # Returns true if redirect was performed, false otherwise.
  def play_in_host_room_if_applicable
    return false unless current_user && session[:host_room_code].present?
    return false unless @track

    room = Room.find_by(code: session[:host_room_code])
    return false unless room&.active?
    return false unless room.host?(current_user)

    authorize room, :play_track?
    Rooms::PlayTrackService.call(room: room, track: @track)
    Rooms::BroadcastPlayerService.call(room: room)
    Rooms::BroadcastSessionStateService.call(room: room, event_type: "play_track")
    redirect_to room_join_path(room.code), notice: t("controllers.tracks.played_in_room", default: "Track playing in room.")
    true
  rescue Pundit::NotAuthorizedError
    false
  end
end
