# frozen_string_literal: true

module Rooms
  # Returns a random track from the room's playlist for online auto-play mode.
  # GET /rooms/:room_id/random_track
  class RandomTracksController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_room

    def show
      playlist = @room.playlist
      unless playlist
        render json: { error: "no_playlist" }, status: :unprocessable_entity
        return
      end

      played_ids = played_track_ids_from_params
      track = playlist.tracks
        .where.not(id: played_ids)
        .where.not(preview_url: [nil, ""])
        .order(Arel.sql("RANDOM()"))
        .first

      # Fall back to any track if all have been played
      track ||= playlist.tracks
        .where.not(preview_url: [nil, ""])
        .order(Arel.sql("RANDOM()"))
        .first

      unless track
        render json: { error: "no_tracks" }, status: :not_found
        return
      end

      render json: {
        id: track.id,
        token: track.token,
        title: track.title,
        artist_name: track.artist_name,
        release_year: track.release_year,
        preview_url: track_preview_stream_path(track.token),
        album_cover_url: track.album_cover_url,
        album_name: track.album_name
      }
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end

    def played_track_ids_from_params
      ids = params[:played_ids].to_s.split(",").map(&:to_i).reject(&:zero?)
      ids.presence || []
    end
  end
end
