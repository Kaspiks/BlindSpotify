# frozen_string_literal: true

module Rooms
  # Pattern B: GET /r/:code/state returns current session state JSON.
  # Clients can request a snapshot or rely on RoomSessionChannel pushes.
  class StateController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_room

    def show
      render json: @room.state_snapshot
    end

    private

    def set_room
      @room = Room.find_by!(code: params[:code])
    end
  end
end
