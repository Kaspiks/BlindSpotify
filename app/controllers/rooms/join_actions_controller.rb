# frozen_string_literal: true

module Rooms
  # Option A: explicit Join step before entering the room. Creates RoomParticipant and broadcasts.
  class JoinActionsController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_room
    before_action :authorize_room_join

    def new
      # If already a participant (e.g. re-visit), go straight to room
      redirect_to room_join_path(@room.code) and return if current_participant.present?
    end

    def create
      if current_participant.present?
        redirect_to room_join_path(@room.code), notice: t_context(".already_joined")
        return
      end

      participant = @room.room_participants.find_or_initialize_by(session_id: participant_session_id)

      if current_user.present?
        participant.participant = current_user
      end

      participant.name = join_params[:name].to_s.strip.presence || t_context(".default_name")

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
      @current_participant ||= @room.room_participants.find_by(session_id: participant_session_id)
    end

    def participant_session_id
      session[:room_participant_sid] ||= SecureRandom.hex(16)
    end

    def join_params
      params.fetch(:rooms_join_action, {}).permit(:name)
    end
  end
end
