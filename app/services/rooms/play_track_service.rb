# frozen_string_literal: true

module Rooms
  class PlayTrackService < ApplicationService
    def initialize(room:, track:)
      @room = room
      @track = track
    end

    def call
      @room.update!(
        current_track_id: @track.id,
        revealed: false
      )
      @room
    end
  end
end
