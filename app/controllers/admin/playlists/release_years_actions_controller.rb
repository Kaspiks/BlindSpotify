# frozen_string_literal: true

module Admin
  module Playlists
    class ReleaseYearsActionsController < Admin::BaseController
      before_action :set_playlist

      def edit
        @form = build_form
        @presenter = build_edit_presenter
      end

      def update
        @form = build_form

        if @form.update(update_params)
          redirect_to admin_playlist_path(@playlist), notice: t_context(".success")
        else
          redirect_to edit_admin_playlist_release_years_path(@playlist),
            alert: @form.errors.full_messages.join(", ")
        end
      end

      private

      def set_playlist
        @playlist = Playlist.find(params[:playlist_id])
      end

      def build_form
        Admin::Playlists::ReleaseYearsActions::Form.new(@playlist)
      end

      def build_edit_presenter
        tracks = @playlist.tracks.ordered.with_attached_qr_code_image
        Admin::Playlists::ShowPresenter.new(playlist: @playlist, tracks: tracks)
      end

      def update_params
        # Accept either param key (form model_name or Simple Form's object)
        raw = params[:admin_playlists_release_years_actions_form] || params[:playlist] || {}
        tracks_raw = raw[:tracks] || raw["tracks"] || {}
        allowed_ids = @playlist.tracks.pluck(:id).map(&:to_s)

        filtered = {}
        tracks_raw.each do |id, attrs|
          next unless allowed_ids.include?(id.to_s)
          
          attrs = attrs.permit(:release_year).to_h if attrs.respond_to?(:permit)
          filtered[id.to_s] = attrs.with_indifferent_access
        end
        { "tracks" => filtered }
      end
    end
  end
end
