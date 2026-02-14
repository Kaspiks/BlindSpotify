# frozen_string_literal: true

module Rooms
  class CodeGenerationService < ApplicationService
    CODE_LENGTH = 6
    MAX_ATTEMPTS = 10

    def initialize
      # no params
    end

    def call
      MAX_ATTEMPTS.times do
        code = SecureRandom.alphanumeric(CODE_LENGTH).upcase
        return code unless Room.exists?(code: code)
      end
      raise "Could not generate unique room code after #{MAX_ATTEMPTS} attempts"
    end
  end
end
