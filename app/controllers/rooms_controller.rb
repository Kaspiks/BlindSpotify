# frozen_string_literal: true

class RoomsController < ApplicationController
  include PresenterHelpers

  skip_before_action :authenticate_user!, only: [:show]

  presents_form :form, presenter_class: FormPresenter

  before_action :set_room, only: [:show]
  before_action :authorize_room_show, only: [:show]

  def show
    unless stitch_public_preview?
      if current_user && @room.host?(current_user)
        session[:host_room_code] = @room.code
      else
        # Option A: guests must have joined (have a participant) to see the room
        sid = session[:room_participant_sid] ||= SecureRandom.hex(16)
        unless @room.room_participants.exists?(session_id: sid)
          redirect_to new_room_join_path(@room.code) and return
        end
      end
    end
    ensure_host_room_participant if current_user && @room.host?(current_user)
    @room_participant = current_room_participant
    @live_room_mode = live_room_mode_param
    render "rooms/show_live", layout: "live_room"
  end

  def show_presenter
    @show_presenter ||= Rooms::ShowPresenter.new(
      object: @room,
      current_user: current_user,
      decorator: RoomDecorator
    )
  end

  def new
    @room = Room.new
    @form = Rooms::Form.new(@room, host: current_user)
    authorize @room
    @presenter = FormPresenter.new(form: @form)
  end

  def create
    @room = Room.new
    @form = Rooms::Form.new(@room, host: current_user)
    authorize @room

    if @form.create(room_params)
      room = @form.object
      Rooms::BroadcastSessionStateService.call(room: room, event_type: "room_created", by: room.host_id.present? ? "p_#{room.host_id}" : nil)
      redirect_to room_join_path(room.code), notice: t_context(".success")
    else
      @room = @form.object
      @presenter = FormPresenter.new(form: @form)
      render_action_with_errors(:new, object: @form)
    end
  end

  private

  def set_room
    @room = Room.find_by!(code: params[:code])
  end

  def authorize_room_show
    authorize @room, :show?
  rescue Pundit::NotAuthorizedError
    redirect_to root_path, alert: t("pundit.room.show_not_authorized", default: "Room not found or closed.")
  end

  def room_params
    params.fetch(:rooms_form, {}).permit(:host_id, :playlist_id)
  end

  def current_room_participant
    sid = session[:room_participant_sid]
    if sid.present?
      by_sid = @room.room_participants.find_by(session_id: sid)
      return by_sid if by_sid
    end

    # Join used session_id; if the cookie rotated or another tab logged in, still
    # resolve the row so live-room `data-player-id` matches game turn ids (p_*).
    if current_user
      @room.room_participants.find_by(participant_id: current_user.id)
    end
  end

  # One RoomParticipant row for the host so session JSON and client use p_<id> consistently.
  def ensure_host_room_participant
    sid = session[:room_participant_sid] ||= SecureRandom.hex(16)
    record = @room.room_participants.find_by(participant_id: current_user.id)
    if record
      record.update!(session_id: sid) if record.session_id != sid
      return
    end

    name = current_user.try(:email).to_s.split("@").first.presence || "Host"
    participant = @room.room_participants.create!(
      session_id: sid,
      participant_id: current_user.id,
      name: name
    )
    Rooms::BroadcastSessionStateService.call(
      room: @room,
      event_type: "player_joined",
      by: "player_#{participant.id}"
    )
  end

  def live_room_mode_param
    m = params[:mode].to_s
    return m if %w[offline hybrid online].include?(m)

    "online"
  end
end
