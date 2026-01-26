# frozen_string_literal: true

module Admin
  class PlaylistsController < BaseController
    before_action :set_playlist, only: %i[show generate_qr_codes download_cards qr_status]

    def index
      @presenter = build_index_presenter
    end

    def show
      @presenter = build_show_presenter
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

      # Prefer ActiveStorage attachment if available
      if @playlist.qr_cards_pdf.attached?
        redirect_to rails_blob_path(@playlist.qr_cards_pdf, disposition: "attachment",
          filename: "#{@playlist.name.parameterize}-cards.pdf"), allow_other_host: true
        return
      end

      # Fallback to tmp file
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

    def build_index_presenter
      playlists = Playlist.includes(:user, :genre, :tracks)
                          .where(import_status: "completed")
                          .order(created_at: :desc)

      Admin::Playlists::IndexPresenter.new(playlists: playlists)
    end

    def build_show_presenter
      tracks = @playlist.tracks.ordered.with_attached_qr_code_image

      Admin::Playlists::ShowPresenter.new(playlist: @playlist, tracks: tracks)
    end
  end
end
