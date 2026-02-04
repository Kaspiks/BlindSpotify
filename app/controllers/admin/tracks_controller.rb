# frozen_string_literal: true

module Admin
  class TracksController < BaseController
    before_action :set_playlist
    before_action :set_track

    def qr_code
      unless @track.qr_code_image.attached?
        redirect_to admin_playlist_path(@playlist), alert: t_context(".not_generated")
        return
      end

      redirect_to rails_blob_path(@track.qr_code_image, disposition: "inline"), allow_other_host: true
    end

    private

    def set_playlist
      @playlist = Playlist.find(params[:playlist_id])
    end

    def set_track
      @track = @playlist.tracks.find(params[:id])
    end
  end
end
