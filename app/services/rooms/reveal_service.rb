# frozen_string_literal: true

module Rooms
  class RevealService < ApplicationService
    def initialize(room:)
      @room = room
    end

    def call
      @room.update!(revealed: true)
      @room
    end
  end
end
