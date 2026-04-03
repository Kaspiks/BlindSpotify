# frozen_string_literal: true

module Rooms
  # Updates room state_json and broadcasts to RoomSessionChannel (Pattern B).
  # Live room UI is React + ActionCable; Turbo player-list replace removed (was tied to Phlex room show).
  # Call after any action that changes room state (play_track, reveal, next, join).
  class BroadcastSessionStateService < ApplicationService
    def initialize(room:, event_type:, by: nil)
      @room = room
      @event_type = event_type
      @by = by
    end

    def call
      room.reload # fresh participants (e.g. after join)
      room.sync_state_json!(event_type: @event_type, by: @by)
      broadcast_state
      room
    end

    private

    attr_reader :room

    def broadcast_state
      ActionCable.server.broadcast(
        "room_session:#{room.code}",
        { "state" => room.state_snapshot }
      )
    end

  end
end
