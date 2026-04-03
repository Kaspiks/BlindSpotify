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

  # Same-origin MP3 stream so browsers do not ORB-block Deezer CDN responses on <audio>.
  # Retries once with a force-refreshed URL when the CDN rejects the cached one (403/etc.)
  # since Deezer's actual expiry can be shorter than our PREVIEW_URL_CACHE_DURATION.
  def preview_stream
    track = Track.find_by(token: params[:token])
    head :not_found and return unless track

    remote_url = track.fresh_preview_url
    head :not_found and return if remote_url.blank?

    begin
      body, content_type = Tracks::FetchPreviewBodyService.call(url: remote_url)
    rescue Tracks::FetchPreviewBodyService::FetchError => e
      Rails.logger.info "[TracksController#preview_stream] first attempt failed (#{e.message}), force-refreshing URL"
      track.update_columns(preview_url_expires_at: 1.second.ago)
      remote_url = track.fresh_preview_url
      raise e if remote_url.blank?
      body, content_type = Tracks::FetchPreviewBodyService.call(url: remote_url)
    end

    send_data body,
      type: content_type,
      disposition: "inline",
      cache_control: "private, max-age=0, must-revalidate"
  rescue Tracks::FetchPreviewBodyService::FetchError => e
    Rails.logger.warn "[TracksController#preview_stream] #{e.message}"
    head :bad_gateway
  end

  def refresh_preview
    @track = Track.find_by(token: params[:token])
    head :not_found and return unless @track

    url = @track.fresh_preview_url
    if url.blank?
      render json: { error: "no_preview" }, status: :not_found
      return
    end

    render json: { preview_url: track_preview_stream_path(@track.token) }
  rescue Deezer::Client::ApiError => e
    Rails.logger.error "[TracksController#refresh_preview] Deezer API error: #{e.message}"
    render json: { error: "Unable to load preview" }, status: :service_unavailable
  end

  # GET /q/:token/playback — JSON for Capacitor/web playback coordinator (preview + external handoff).
  def playback
    @track = Track.find_by(token: params[:token])
    head :not_found and return unless @track

    json = @track.playback_client_json(
      refresh_preview_path: refresh_track_preview_path(@track.token)
    )
    json[:preview_url] = track_preview_stream_path(@track.token)
    render json: json
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
