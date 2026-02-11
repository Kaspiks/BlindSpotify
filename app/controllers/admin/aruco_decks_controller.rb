# frozen_string_literal: true

module Admin
  class ArucoDecksController < BaseController
    before_action :set_aruco_deck, only: %i[show assign_playlist generate_qr_codes download_cards qr_status]

    def index
      @presenter = build_index_presenter
    end

    def show
      @presenter = build_show_presenter
    end

    def new
      @aruco_deck = ArucoDeck.new
    end

    def create
      @aruco_deck = ArucoDeck.new(aruco_deck_params)

      if @aruco_deck.save
        redirect_to admin_aruco_deck_path(@aruco_deck), notice: t_context(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def assign_playlist
      if params[:playlist_id].blank?
        redirect_to admin_aruco_deck_path(@aruco_deck), alert: t_context(".playlist_required")
        return
      end

      playlist = Playlist.find(params[:playlist_id])
      @aruco_deck.assign_playlist!(playlist)
      redirect_to admin_aruco_deck_path(@aruco_deck), notice: t_context(".success")
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_aruco_deck_path(@aruco_deck), alert: t_context(".playlist_not_found")
    end

    def generate_qr_codes
      unless @aruco_deck.can_generate_qr_codes?
        redirect_to admin_aruco_deck_path(@aruco_deck), alert: t_context(".cannot_generate")
        return
      end

      @aruco_deck.start_qr_generation!
      DeckQrCodesGenerationJob.perform_later(@aruco_deck.id)
      redirect_to admin_aruco_deck_path(@aruco_deck), notice: t_context(".started")
    end

    def download_cards
      if @aruco_deck.qr_cards_pdf.attached?
        redirect_to rails_blob_path(@aruco_deck.qr_cards_pdf,
          disposition: "attachment",
          filename: "#{@aruco_deck.name.parameterize}-aruco-cards.pdf"),
          allow_other_host: true
        return
      end

      redirect_to admin_aruco_deck_path(@aruco_deck), alert: t_context(".not_generated")
    end

    def qr_status
      render json: {
        status: @aruco_deck.qr_status,
        qr_generated_count: @aruco_deck.qr_generated_count,
        slots_count: @aruco_deck.slots_count,
        progress: @aruco_deck.qr_progress_percentage
      }
    end

    private

    def set_aruco_deck
      @aruco_deck = ArucoDeck.find(params[:id])
    end

    def aruco_deck_params
      params.require(:aruco_deck).permit(:name, :slots_count)
    end

    def build_index_presenter
      decks = ArucoDeck.includes(:playlist, :aruco_deck_slots).order(created_at: :desc)
      Admin::ArucoDecks::IndexPresenter.new(decks: decks)
    end

    def build_show_presenter
      Admin::ArucoDecks::ShowPresenter.new(aruco_deck: @aruco_deck)
    end
  end
end
