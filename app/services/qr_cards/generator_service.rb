# frozen_string_literal: true

require "rqrcode"
require "rqrcode_png"
require "prawn"
require "digest"
require "stringio"
require "tempfile"
require "fileutils"

module QrCards
  class GeneratorService < ApplicationService
    CARD_WIDTH = 180
    CARD_HEIGHT = 252
    CARD_MARGIN = 10
    CARDS_PER_ROW = 3
    CARDS_PER_PAGE = 6

    QR_PNG_PIXEL_SIZE = 600
    QR_PNG_BORDER_MODULES = 4

    def initialize(playlist, on_progress: nil)
      @playlist = playlist
      @on_progress = on_progress
      @qr_png_temp_paths = {}
    end

    def call
      @playlist.start_qr_generation!
      notify_progress

      begin
        tracks = @playlist.tracks.ordered.with_attached_qr_code_image.to_a

        pre_generate_qr_attachments!(tracks)

        pdf_path = self.class.pdf_path(@playlist)

        generate_pdf(tracks, pdf_path)

        attach_pdf_to_playlist!(pdf_path)

        @playlist.complete_qr_generation!
        notify_progress

        success(@playlist, pdf_path)
      rescue StandardError => e
        Rails.logger.error "QR generation failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        @playlist.fail_qr_generation!(e.message)
        notify_progress
        failure(e.message)
      ensure
        cleanup_tmp_files!(self.class.pdf_path(@playlist))
        cleanup_cached_qr_png_tempfiles!
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
        pdf.text_box sanitize_for_pdf(track.artist_name.to_s.upcase),
                     at: [content_x, content_y],
                     width: content_width,
                     height: 40,
                     align: :center,
                     valign: :top,
                     overflow: :shrink_to_fit
      end

      pdf.fill_color "000000"
      pdf.font_size(14) do
        pdf.text_box sanitize_for_pdf(track.title.to_s),
                     at: [content_x, content_y - 60],
                     width: content_width,
                     height: 80,
                     align: :center,
                     valign: :center,
                     overflow: :shrink_to_fit,
                     style: :bold
      end

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

      pdf.stroke_color "CCCCCC"
      pdf.stroke_rectangle [x, y], CARD_WIDTH, CARD_HEIGHT

      qr_size = CARD_WIDTH - 40
      qr_x = x + (CARD_WIDTH - qr_size) / 2
      qr_y = y - (CARD_HEIGHT - qr_size) / 2

      path = cached_qr_png_path(track)

      pdf.image path, at: [qr_x, qr_y], width: qr_size, height: qr_size

      pdf.fill_color "999999"
      pdf.font_size(7) do
        pdf.text_box "Scan to play",
                     at: [x, y - CARD_HEIGHT + 18],
                     width: CARD_WIDTH,
                     height: 12,
                     align: :center
      end
    end

    def cached_qr_png_path(track)
      @qr_png_temp_paths[track.id] ||= begin
        f = Tempfile.new(["qr_track_#{track.id}", ".png"])
        f.binmode
        f.write(track.qr_code_image.download)
        f.flush
        f.path
      end
    end

    def pre_generate_qr_attachments!(tracks)
      tracks.each_with_index do |track, i|
        qr_url = Rails.application.routes.url_helpers.track_qr_url(
          token: track.token,
          **default_url_options
        )

        ensure_qr_attached!(track, qr_url)

        notify_progress if ((i + 1) % 10).zero?
      end
    end

    def ensure_qr_attached!(track, qr_url)
      digest = Digest::SHA256.hexdigest(qr_url)
      return if track.qr_code_image.attached? && track.qr_code_digest == digest

      qr = RQRCode::QRCode.new(qr_url, level: :m)
      png_bytes = qr.as_png(
        size: QR_PNG_PIXEL_SIZE,
        border_modules: QR_PNG_BORDER_MODULES,
        color: "black",
        fill: "white"
      ).to_s

      track.qr_code_image.purge_later if track.qr_code_image.attached?

      track.qr_code_image.attach(
        io: StringIO.new(png_bytes),
        filename: "track_#{track.id}_qr.png",
        content_type: "image/png"
      )

      track.update!(qr_code_digest: digest)
    end

    def attach_pdf_to_playlist!(pdf_path)
      @playlist.qr_cards_pdf.purge_later if @playlist.qr_cards_pdf.attached?

      File.open(pdf_path, "rb") do |file|
        @playlist.qr_cards_pdf.attach(
          io: file,
          filename: "playlist_#{@playlist.id}_qr_cards.pdf",
          content_type: "application/pdf"
        )
      end
    end

    def cleanup_tmp_files!(pdf_path)
      File.delete(pdf_path) if File.exist?(pdf_path)
    end

    def cleanup_cached_qr_png_tempfiles!
      @qr_png_temp_paths.each_value do |path|
        File.delete(path) if path && File.exist?(path)
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

    def sanitize_for_pdf(text)
      return "" if text.blank?

      # Use ActiveSupport's transliterate to convert accented characters to ASCII
      # This handles most European characters gracefully
      ActiveSupport::Inflector.transliterate(text)
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
