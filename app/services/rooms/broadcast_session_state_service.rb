# frozen_string_literal: true

module Rooms
  # Updates room state_json and broadcasts to RoomSessionChannel (Pattern B).
  # Also broadcasts the players list via Turbo Stream so host/players see updates.
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
      broadcast_players_list
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

    def broadcast_players_list
      Turbo::StreamsChannel.broadcast_replace_to(
        "room_#{room.id}",
        target: "room_players",
        partial: "rooms/room_players",
        locals: { room: room }
      )
    end
  end
end
