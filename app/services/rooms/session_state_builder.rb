# frozen_string_literal: true

module Rooms
  # Builds the Pattern B "session blob" state from a Room.
  # Server is authoritative; clients receive this state via RoomSessionChannel.
  class SessionStateBuilder < ApplicationService
    SCHEMA_VERSION = 1

    def initialize(room:)
      @room = room
    end

    def call
      {
        "v" => SCHEMA_VERSION,
        "phase" => phase,
        "room" => room_info,
        "players" => players_hash,
        "round" => round_info,
        "last_event" => last_event
      }
    end

    private

    attr_reader :room

    def phase
      return "lobby" if room.current_track_id.blank?
      room.revealed? ? "reveal" : "playing"
    end

    def room_info
      {
        "code" => room.code,
        "host_player_id" => room.host_id.present? ? "#{room.host_id}" : nil,
        "player" => room.host_id.present? ? "host_#{room.host_id}" : nil
      }.compact
    end

    def players_hash
      room.room_participants.index_with do |p|
        {
          "name" => p.name.presence || "Player",
          "score" => 0,
          "connected" => true,
          "role" => "player"
        }
      end.transform_keys { |p| "p_#{p.id}" }
    end

    def round_info
      track = room.current_track
      {
        "status" => phase,
        "track_id" => room.current_track_id,
        "revealed" => room.revealed?,
        "card" => track ? track_card_info(track) : nil
      }.compact
    end

    def track_card_info(track)
      {
        "track_id" => track.id,
        "title" => (room.revealed? ? track.title : nil),
        "artist_name" => (room.revealed? ? track.artist_name : nil),
        "release_year" => (room.revealed? ? track.release_year : nil),
        "preview_url" => track.preview_url,
        "album_cover_url" => (room.revealed? ? track.album_cover_url : nil)
      }.compact
    end

    def last_event
      (room.state_json || {}).dig("last_event") || {
        "id" => 0,
        "at" => room.updated_at.to_i,
        "type" => "room_created",
        "by" => nil
      }
    end
  end
end
