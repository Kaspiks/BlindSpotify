# frozen_string_literal: true

module Rooms
  # Option A: explicit Join step before entering the room. Creates RoomParticipant and broadcasts.
  class JoinActionsController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_room
    before_action :authorize_room_join

    def new
      # Room host always enters via show; never needs the nickname step here.
      redirect_to room_join_path(@room.code) and return if current_user.present? && @room.host?(current_user)
      # Already in this room (session or same logged-in account)
      redirect_to room_join_path(@room.code) and return if current_participant.present?

      @prefill_display_name =
        current_user.try(:email).to_s.split("@").first.presence ||
        current_user.try(:name).to_s.presence
    end

    def create
      if current_participant.present?
        redirect_to room_join_path(@room.code), notice: t_context(".already_joined")
        return
      end

      sid = participant_session_id
      # Logged-in: one row per user in this room (avoid duplicate host + nickname rows)
      participant =
        if current_user.present?
          @room.room_participants.find_by(participant_id: current_user.id) ||
            @room.room_participants.find_or_initialize_by(session_id: sid)
        else
          @room.room_participants.find_or_initialize_by(session_id: sid)
        end

      participant.session_id = sid
      if current_user.present?
        participant.participant = current_user
      end

      participant.name =
        join_params[:name].to_s.strip.presence ||
        current_user.try(:email).to_s.split("@").first.presence ||
        t_context(".default_name")

      if participant.save
        Rooms::BroadcastSessionStateService.call(
          room: @room,
          event_type: "player_joined",
          by: "player_#{participant.id}"
        )
        redirect_to room_join_path(@room.code), notice: t_context(".success")
      else
        @name = join_params[:name]
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_room
      @room = Room.find_by!(code: params[:code])
    end

    def authorize_room_join
      authorize @room, :show?
    rescue Pundit::NotAuthorizedError
      redirect_to root_path, alert: t("pundit.room.show_not_authorized", default: "Room not found or closed.")
    end

    def current_participant
      @current_participant ||= begin
        sid = session[:room_participant_sid]
        by_sid = sid.present? ? @room.room_participants.find_by(session_id: sid) : nil
        by_sid || (current_user && @room.room_participants.find_by(participant_id: current_user.id))
      end
    end

    def participant_session_id
      session[:room_participant_sid] ||= SecureRandom.hex(16)
    end

    def join_params
      params.fetch(:rooms_join_action, {}).permit(:name)
    end
  end
end
