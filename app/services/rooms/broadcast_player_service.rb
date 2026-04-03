# frozen_string_literal: true

module Rooms
  class BroadcastPlayerService < ApplicationService
    def initialize(room:)
      @room = room # retained for call-site compatibility
    end

    def call
      # Live room UI is React + RoomSessionChannel; Turbo replace for legacy Slim partial removed.
    end
  end
end
