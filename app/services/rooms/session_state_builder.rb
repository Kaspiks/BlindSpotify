# frozen_string_literal: true

module Rooms
  # Builds the Pattern B "session blob" state from a Room.
  # Server is authoritative; clients receive this state via RoomSessionChannel.
  #
  # Phase 2 (live room): extend this blob + ApplyRoomActionService for server-authoritative
  # turn order, guess windows, steal phase, and scores so online play matches offline rules.
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
      host_p = room.host_id.present? ? room.room_participants.find_by(participant_id: room.host_id) : nil
      host_key = host_p ? "p_#{host_p.id}" : (room.host_id.present? ? room.host_id.to_s : nil)
      {
        "code" => room.code,
        "host_player_id" => host_key
      }.compact
    end

    def players_hash
      room.room_participants.index_with do |p|
        role =
          if room.host_id.present? && p.participant_id.present? && p.participant_id == room.host_id
            "host"
          else
            "player"
          end
        {
          "name" => p.name.presence || "Player",
          "score" => 0,
          "connected" => true,
          "role" => role
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
        "preview_url" => Rails.application.routes.url_helpers.track_preview_stream_path(track.token),
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
