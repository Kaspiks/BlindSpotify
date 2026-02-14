# frozen_string_literal: true

module Rooms
  class BroadcastPlayerService < ApplicationService
    TARGET_DOM_ID = "room_player"

    def initialize(room:)
      @room = room
    end

    def call
      Turbo::StreamsChannel.broadcast_replace_to(
        "room_#{@room.id}",
        target: TARGET_DOM_ID,
        partial: "rooms/room_player",
        locals: { room: @room }
      )
    end
  end
end
