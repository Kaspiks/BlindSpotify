# frozen_string_literal: true

module Admin
  class PlaylistsController < BaseController
    before_action :set_playlist, only: %i[show generate_qr_codes download_cards qr_status]

    def index
      @playlists = Playlist.includes(:user, :genre, :tracks)
                           .where(import_status: "completed")
                           .order(created_at: :desc)
    end

    def show
      @tracks = @playlist.tracks.ordered
    end

    def generate_qr_codes
      unless @playlist.can_generate_qr_codes?
        redirect_to admin_playlist_path(@playlist), alert: "Cannot generate QR codes for this playlist"
        return
      end

      # Reset QR status on tracks and start generating
      @playlist.tracks.update_all(qr_generated: false)
      @playlist.update!(qr_status: "generating", qr_generated_count: 0, qr_error: nil)

      QrCodesGenerationJob.perform_later(@playlist.id)
      redirect_to admin_playlist_path(@playlist), notice: "QR code generation started"
    end

    def download_cards
      unless @playlist.qr_completed?
        redirect_to admin_playlist_path(@playlist), alert: "QR codes have not been generated yet"
        return
      end

      pdf_path = QrCards::GeneratorService.pdf_path(@playlist)

      unless File.exist?(pdf_path)
        redirect_to admin_playlist_path(@playlist), alert: "PDF file not found. Please regenerate QR codes."
        return
      end

      send_file pdf_path,
                filename: "#{@playlist.name.parameterize}-cards.pdf",
                type: "application/pdf",
                disposition: "attachment"
    end

    def qr_status
      render json: {
        status: @playlist.qr_status,
        qr_generated_count: @playlist.qr_generated_count,
        tracks_count: @playlist.tracks_count,
        progress: @playlist.qr_progress_percentage
      }
    end

    private

    def set_playlist
      @playlist = Playlist.find(params[:id])
    end
  end
end
