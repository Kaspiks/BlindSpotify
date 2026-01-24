# frozen_string_literal: true

require "rqrcode"
require "prawn"

module QrCards
  class GeneratorService < ApplicationService
    # Card dimensions in points (72 points = 1 inch)
    # Using poker card size: 2.5" x 3.5"
    CARD_WIDTH = 180   # ~2.5 inches
    CARD_HEIGHT = 252  # ~3.5 inches
    CARD_MARGIN = 10
    CARDS_PER_ROW = 3
    CARDS_PER_PAGE = 6  # 3x2 grid

    def initialize(playlist, on_progress: nil)
      @playlist = playlist
      @on_progress = on_progress
    end

    def call
      @playlist.start_qr_generation!
      notify_progress

      begin
        tracks = @playlist.tracks.ordered.to_a
        pdf_path = self.class.pdf_path(@playlist)

        generate_pdf(tracks, pdf_path)

        @playlist.complete_qr_generation!
        notify_progress

        success(@playlist, pdf_path)
      rescue StandardError => e
        Rails.logger.error "QR generation failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        @playlist.fail_qr_generation!(e.message)
        notify_progress
        failure(e.message)
      end
    end

    def self.pdf_path(playlist)
      Rails.root.join("tmp", "qr_cards", "playlist_#{playlist.id}.pdf").to_s
    end

    private

    def generate_pdf(tracks, pdf_path)
      FileUtils.mkdir_p(File.dirname(pdf_path))

      Prawn::Document.generate(pdf_path, page_size: "A4", margin: 36) do |pdf|
        # Generate info pages first (front of cards)
        generate_info_pages(pdf, tracks)

        # Generate QR pages (back of cards) - reversed order for double-sided printing
        generate_qr_pages(pdf, tracks)
      end

      Rails.logger.info "[QrCards::GeneratorService] Generated PDF at #{pdf_path}"
    end

    def generate_info_pages(pdf, tracks)
      tracks.each_slice(CARDS_PER_PAGE).with_index do |page_tracks, page_index|
        pdf.start_new_page if page_index > 0

        page_tracks.each_with_index do |track, index|
          draw_info_card(pdf, track, index)
        end
      end
    end

    def generate_qr_pages(pdf, tracks)
      tracks.each_slice(CARDS_PER_PAGE).with_index do |page_tracks, _page_index|
        pdf.start_new_page

        # Reverse the row order for double-sided printing alignment
        # When printed double-sided, the QR codes will align with info cards
        page_tracks_reversed = reverse_rows_for_printing(page_tracks)

        page_tracks_reversed.each_with_index do |track, index|
          next if track.nil?

          draw_qr_card(pdf, track, index)
          track.mark_qr_generated!
          @playlist.increment_qr_generated_count!

          # Broadcast progress every few tracks
          notify_progress if (@playlist.qr_generated_count % 5).zero?
        end
      end
    end

    def reverse_rows_for_printing(tracks)
      # Pad to full page
      padded = tracks + [nil] * (CARDS_PER_PAGE - tracks.size)

      # Split into rows and reverse column order within each row for mirror effect
      rows = padded.each_slice(CARDS_PER_ROW).to_a
      rows.flat_map { |row| row.reverse }
    end

    def card_position(index)
      row = index / CARDS_PER_ROW
      col = index % CARDS_PER_ROW

      x = col * (CARD_WIDTH + CARD_MARGIN)
      # Y is from top of page content area
      y = 720 - (row * (CARD_HEIGHT + CARD_MARGIN))

      [x, y]
    end

    def draw_info_card(pdf, track, index)
      x, y = card_position(index)

      # Card border
      pdf.stroke_color "CCCCCC"
      pdf.stroke_rectangle [x, y], CARD_WIDTH, CARD_HEIGHT

      # Content area with padding
      content_x = x + 15
      content_y = y - 20
      content_width = CARD_WIDTH - 30

      # Artist name (top)
      pdf.fill_color "666666"
      pdf.font_size(11) do
        pdf.text_box track.artist_name.to_s.upcase,
                     at: [content_x, content_y],
                     width: content_width,
                     height: 40,
                     align: :center,
                     valign: :top,
                     overflow: :shrink_to_fit
      end

      # Song title (center)
      pdf.fill_color "000000"
      pdf.font_size(14) do
        pdf.text_box track.title.to_s,
                     at: [content_x, content_y - 60],
                     width: content_width,
                     height: 80,
                     align: :center,
                     valign: :center,
                     overflow: :shrink_to_fit,
                     style: :bold
      end

      # Year (bottom) - if available
      if track.release_year.present?
        pdf.fill_color "333333"
        pdf.font_size(24) do
          pdf.text_box track.release_year.to_s,
                       at: [content_x, y - CARD_HEIGHT + 50],
                       width: content_width,
                       height: 30,
                       align: :center,
                       valign: :bottom,
                       style: :bold
        end
      end

      # Track number (small, bottom corner)
      pdf.fill_color "AAAAAA"
      pdf.font_size(8) do
        pdf.text_box "##{track.position}",
                     at: [x + 5, y - CARD_HEIGHT + 15],
                     width: 30,
                     height: 12
      end
    end

    def draw_qr_card(pdf, track, index)
      x, y = card_position(index)

      # Card border
      pdf.stroke_color "CCCCCC"
      pdf.stroke_rectangle [x, y], CARD_WIDTH, CARD_HEIGHT

      # Generate QR code
      qr_url = Rails.application.routes.url_helpers.track_qr_url(
        token: track.token,
        **default_url_options
      )

      qr = RQRCode::QRCode.new(qr_url, level: :m)
      qr_size = CARD_WIDTH - 40

      # Center QR code in card
      qr_x = x + (CARD_WIDTH - qr_size) / 2
      qr_y = y - (CARD_HEIGHT - qr_size) / 2

      draw_qr_code(pdf, qr, qr_x, qr_y, qr_size)

      # Small label at bottom
      pdf.fill_color "999999"
      pdf.font_size(7) do
        pdf.text_box "Scan to play",
                     at: [x, y - CARD_HEIGHT + 18],
                     width: CARD_WIDTH,
                     height: 12,
                     align: :center
      end
    end

    def draw_qr_code(pdf, qr, x, y, size)
      module_count = qr.modules.size
      module_size = size.to_f / module_count

      pdf.fill_color "000000"

      qr.modules.each_with_index do |row, row_index|
        row.each_with_index do |cell, col_index|
          next unless cell

          pdf.fill_rectangle(
            [x + (col_index * module_size), y - (row_index * module_size)],
            module_size,
            module_size
          )
        end
      end
    end

    def default_url_options
      # Use configured URL options (host + port) or fallback
      Rails.application.config.action_mailer.default_url_options ||
        { host: ENV.fetch("APP_HOST", "localhost"), port: ENV.fetch("APP_PORT", 3000) }
    end

    def notify_progress
      @on_progress&.call(@playlist)
    end

    def success(playlist, pdf_path)
      Result.new(success: true, playlist: playlist, pdf_path: pdf_path, error: nil)
    end

    def failure(error)
      Result.new(success: false, playlist: @playlist, pdf_path: nil, error: error)
    end

    Result = Struct.new(:success, :playlist, :pdf_path, :error, keyword_init: true) do
      def success?
        success
      end

      def failure?
        !success
      end
    end
  end
end
