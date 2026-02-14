# frozen_string_literal: true

module Rooms
  class NextTrackService < ApplicationService
    def initialize(room:)
      @room = room
    end

    def call
      @room.update!(
        current_track_id: nil,
        revealed: false
      )
      @room
    end
  end
end
