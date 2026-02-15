# frozen_string_literal: true

module Rooms
  # Applies an action to a room (Pattern B: server is authoritative).
  # Used from HTTP controllers and optionally from RoomSessionChannel#receive.
  # Clients send action types; we never accept full state from clients.
  class ApplyRoomActionService < ApplicationService
    def initialize(room:, action:, payload: {}, connection: nil)
      @room = room
      @action = action.to_s
      @payload = payload.with_indifferent_access
      @connection = connection
    end

    def call
      apply_action
      Rooms::BroadcastSessionStateService.call(
        room: @room,
        event_type: @action,
        by: @payload[:by] || @payload["by"]
      )
      @room
    end

    private

    def apply_action
      case @action
      when "play_track", "start_round", "scan_card"
        apply_play_track
      when "reveal_round", "reveal"
        apply_reveal
      when "next_round", "next"
        apply_next
      when "join"
        apply_join
      else
        Rails.logger.warn "[ApplyRoomActionService] Unknown action: #{@action}"
      end
    end

    def apply_play_track
      track = resolve_track(
        track_id: @payload[:track_id] || @payload["track_id"],
        track_token: @payload[:track_token] || @payload["track_token"],
        deck_id: @payload[:deck_id] || @payload["deck_id"],
        position: @payload[:position] || @payload["position"]
      )
      Rooms::PlayTrackService.call(room: @room, track: track) if track
    end

    def apply_reveal
      Rooms::RevealService.call(room: @room)
    end

    def apply_next
      Rooms::NextTrackService.call(room: @room)
    end

    def apply_join
      # Join is typically handled by HTTP (session-based participant). Optional: create participant from payload.
      name = @payload[:name] || @payload["name"]
      return if name.blank?
      session_id = @connection&.connection&.session&.dig("session_id") || SecureRandom.hex(16)
      participant = @room.room_participants.find_or_initialize_by(session_id: session_id)
      participant.name = name
      participant.save!
    end

    def resolve_track(track_id: nil, track_token: nil, deck_id: nil, position: nil)
      if track_id.present?
        Track.find_by(id: track_id)
      elsif track_token.present?
        Track.find_by(token: track_token)
      elsif deck_id.present? && position.present?
        deck = ArucoDeck.find_by(id: deck_id)
        deck&.slot_at(position.to_i)
      end
    end
  end
end
