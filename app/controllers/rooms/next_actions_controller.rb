# frozen_string_literal: true

module Rooms
  class NextActionsController < ApplicationController
    before_action :set_room
    before_action :authorize_room_next

    def create
      Rooms::NextTrackService.call(room: @room)
      Rooms::BroadcastPlayerService.call(room: @room)
      redirect_to room_join_path(@room.code), notice: t_context(".success")
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end

    def authorize_room_next
      authorize @room, :next?
    end
  end
end