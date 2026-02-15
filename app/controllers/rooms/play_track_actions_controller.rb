# frozen_string_literal: true

module Rooms
  class PlayTrackActionsController < ApplicationController
    before_action :set_room
    before_action :authorize_room_play_track

    def new
      @form = build_form
      @presenter = FormPresenter.new(form: @form)
    end

    def create
      @form = build_form
      if @form.create(permitted_params)
        Rooms::BroadcastPlayerService.call(room: @room)
        Rooms::BroadcastSessionStateService.call(room: @room, event_type: "play_track")
        redirect_to room_join_path(@room.code), notice: t_context(".success")
      else
        @presenter = FormPresenter.new(form: @form)
        render_action_with_errors(:new, object: @form)
      end
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end

    def authorize_room_play_track
      authorize @room, :play_track?
    end

    def build_form
      PlayTrackActions::Form.new(@room)
    end

    def permitted_params
      params.fetch(:rooms_play_track_actions_form, {}).permit(
        :track_id, :track_token, :deck_id, :position
      )
    end
  end
end
