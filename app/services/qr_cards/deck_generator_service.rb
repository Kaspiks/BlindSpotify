# frozen_string_literal: true

require "rqrcode"
require "rqrcode_png"
require "prawn"
require "digest"
require "stringio"
require "tempfile"
require "fileutils"

module QrCards
  # Generates printable QR-code card sheets for an ArUco deck.
  #
  # Front side: ArUco marker (if available) or placeholder text.
  # Back side:  QR code pointing to the deck-slot URL (/q/d/:deck_id/:position),
  #             which can be reassigned to a different playlist at any time.
  class DeckGeneratorService < ApplicationService
    CARD_WIDTH = 180
    CARD_HEIGHT = 252
    CARD_MARGIN = 10
    CARDS_PER_ROW = 3
    CARDS_PER_PAGE = 6

    QR_PNG_PIXEL_SIZE = 600
    QR_PNG_BORDER_MODULES = 4

    def initialize(deck, on_progress: nil)
      @deck = deck
      @on_progress = on_progress
      @qr_png_temp_paths = {}
      @aruco_resolver = QrCards::ArucoMarkerResolver.new(
        generator_url: ENV["ARUCO_GENERATOR_URL"]
      )
    end

    def call
      @deck.start_qr_generation!
      notify_progress

      begin
        slots = @deck.aruco_deck_slots.includes(:track).order(:position).to_a

        # Refresh preview URLs and skip slots whose tracks have no Deezer preview
        refresh_preview_urls!(slots)
        slots = slots.select { |s| s.track.preview_url.present? }

        Rails.logger.info "[DeckQR] #{slots.size}/#{@deck.slots_count} slots have playable previews"

        pre_generate_qr_attachments!(slots)

        pdf_path = self.class.pdf_path(@deck)
        generate_pdf(slots, pdf_path)
        attach_pdf_to_deck!(pdf_path)

        @deck.complete_qr_generation!
        notify_progress

        success(@deck, pdf_path)
      rescue StandardError => e
        Rails.logger.error "Deck QR generation failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        @deck.fail_qr_generation!(e.message)
        notify_progress
        failure(e.message)
      ensure
        cleanup_tmp_files!(self.class.pdf_path(@deck))
        cleanup_cached_qr_png_tempfiles!
        @aruco_resolver.cleanup!
      end
    end

    def self.pdf_path(deck)
      Rails.root.join("tmp", "qr_cards", "deck_#{deck.id}.pdf").to_s
    end

    private

    # ── PDF generation ──────────────────────────────────────────

    def generate_pdf(slots, pdf_path)
      FileUtils.mkdir_p(File.dirname(pdf_path))

      pdf = Prawn::Document.new(page_size: "A4", margin: 36)
      setup_unicode_font(pdf)
      generate_interleaved_pages(pdf, slots)
      pdf.render_file(pdf_path)
    end

    def setup_unicode_font(pdf)
      font_dir = Rails.root.join("vendor", "fonts")
      normal_font = font_dir.join("DejaVuSans.ttf").to_s
      bold_font = font_dir.join("DejaVuSans-Bold.ttf").to_s

      return unless File.exist?(normal_font) && File.exist?(bold_font)

      pdf.font_families.update(
        "DejaVuSans" => { normal: normal_font, bold: bold_font }
      )
      pdf.font "DejaVuSans"
    rescue StandardError
    end

    def generate_interleaved_pages(pdf, slots)
      slots.each_slice(CARDS_PER_PAGE).with_index do |page_slots, page_index|
        pdf.start_new_page if page_index > 0

        # Front side: ArUco markers
        page_slots.each_with_index do |slot, index|
          draw_front_card(pdf, slot, index)
        end

        # Back side: QR codes
        pdf.start_new_page
        reversed = reverse_rows_for_printing(page_slots)
        reversed.each_with_index do |slot, index|
          next if slot.nil?

          draw_qr_card(pdf, slot, index)
          @deck.increment_qr_generated_count!
          notify_progress if (@deck.qr_generated_count % 5).zero?
        end
      end
    end

    def reverse_rows_for_printing(slots)
      padded = slots + [nil] * (CARDS_PER_PAGE - slots.size)
      padded.reverse
    end

    def card_position(index)
      row = index / CARDS_PER_ROW
      col = index % CARDS_PER_ROW
      x = col * (CARD_WIDTH + CARD_MARGIN)
      y = 720 - (row * (CARD_HEIGHT + CARD_MARGIN))
      [x, y]
    end

    # ── Front card: ArUco marker or text fallback ───────────────

    def draw_front_card(pdf, slot, index)
      x, y = card_position(index)
      track = slot.track

      pdf.stroke_color "CCCCCC"
      pdf.stroke_rectangle [x, y], CARD_WIDTH, CARD_HEIGHT

      marker_id = QrCards::ArucoMarkerResolver.marker_id_for_track(track)
      marker_path = @aruco_resolver.path_for_marker(marker_id)

      if marker_path.present?
        draw_aruco_front(pdf, x, y, marker_path, slot.position)
      else
        draw_text_front(pdf, x, y, track)
      end
    end

    def draw_aruco_front(pdf, x, y, marker_path, position)
      marker_size = CARD_WIDTH - 30
      marker_x = x + (CARD_WIDTH - marker_size) / 2
      marker_y = y - (CARD_HEIGHT - marker_size) / 2 - 10
      pdf.image marker_path, at: [marker_x, marker_y], width: marker_size, height: marker_size

      pdf.fill_color "999999"
      pdf.font_size(7) do
        pdf.text_box "Scan deck to identify",
                     at: [x, y - CARD_HEIGHT + 18], width: CARD_WIDTH, height: 12, align: :center
      end

      pdf.fill_color "AAAAAA"
      pdf.font_size(8) do
        pdf.text_box "##{position}", at: [x + 5, y - CARD_HEIGHT + 15], width: 30, height: 12
      end
    end

    def draw_text_front(pdf, x, y, track)
      content_x = x + 15
      content_y = y - 20
      content_width = CARD_WIDTH - 30

      pdf.fill_color "666666"
      pdf.font_size(11) do
        pdf.text_box sanitize_for_pdf(track.artist_name.to_s.upcase),
                     at: [content_x, content_y], width: content_width, height: 40,
                     align: :center, valign: :top, overflow: :shrink_to_fit
      end

      pdf.fill_color "000000"
      pdf.font_size(14) do
        pdf.text_box sanitize_for_pdf(track.title.to_s),
                     at: [content_x, content_y - 60], width: content_width, height: 80,
                     align: :center, valign: :center, overflow: :shrink_to_fit, style: :bold
      end

      if track.release_year.present?
        pdf.fill_color "333333"
        pdf.font_size(24) do
          pdf.text_box track.release_year.to_s,
                       at: [content_x, y - CARD_HEIGHT + 50], width: content_width, height: 30,
                       align: :center, valign: :bottom, style: :bold
        end
      end

      pdf.fill_color "AAAAAA"
      pdf.font_size(8) do
        pdf.text_box "##{track.position}", at: [x + 5, y - CARD_HEIGHT + 15], width: 30, height: 12
      end
    end

    # ── QR card (back side) ─────────────────────────────────────

    def draw_qr_card(pdf, slot, index)
      x, y = card_position(index)

      pdf.stroke_color "CCCCCC"
      pdf.stroke_rectangle [x, y], CARD_WIDTH, CARD_HEIGHT

      qr_size = CARD_WIDTH - 40
      qr_x = x + (CARD_WIDTH - qr_size) / 2
      qr_y = y - (CARD_HEIGHT - qr_size) / 2

      path = cached_qr_png_path(slot)
      pdf.image path, at: [qr_x, qr_y], width: qr_size, height: qr_size

      pdf.fill_color "999999"
      pdf.font_size(7) do
        pdf.text_box "Scan to play",
                     at: [x, y - CARD_HEIGHT + 18], width: CARD_WIDTH, height: 12, align: :center
      end
    end

    # ── QR code generation ──────────────────────────────────────

    def refresh_preview_urls!(slots)
      slots.each do |slot|
        track = slot.track
        next if track.preview_url_valid?

        track.refresh_preview_url!
      rescue StandardError => e
        Rails.logger.warn "[DeckQR] Could not refresh preview for track #{track.id}: #{e.message}"
      end
    end

    def pre_generate_qr_attachments!(slots)
      helpers = Rails.application.routes.url_helpers

      slots.each_with_index do |slot, i|
        qr_url = helpers.track_qr_deck_slot_url(
          deck_id: @deck.id,
          position: slot.position,
          **default_url_options
        )

        ensure_qr_attached!(slot.track, qr_url)
        notify_progress if ((i + 1) % 10).zero?
      end
    end

    def ensure_qr_attached!(track, qr_url)
      digest = Digest::SHA256.hexdigest(qr_url)

      if track.qr_code_image.attached? && track.qr_code_digest == digest
        begin
          track.qr_code_image.blob.open { |_| } if track.qr_code_image.blob.present?
          return
        rescue ActiveStorage::FileNotFoundError
          Rails.logger.info "[DeckQR] File missing for track #{track.id}, regenerating..."
        end
      end

      qr = RQRCode::QRCode.new(qr_url, level: :m)
      png_bytes = qr.as_png(
        size: QR_PNG_PIXEL_SIZE,
        border_modules: QR_PNG_BORDER_MODULES,
        color: "black",
        fill: "white"
      ).to_s

      track.qr_code_image.purge if track.qr_code_image.attached?
      track.qr_code_image.attach(
        io: StringIO.new(png_bytes),
        filename: "track_#{track.id}_qr.png",
        content_type: "image/png"
      )
      track.update!(qr_code_digest: digest)
    end

    def cached_qr_png_path(slot)
      track = slot.track
      @qr_png_temp_paths[track.id] ||= begin
        f = Tempfile.new(["qr_deck_#{track.id}", ".png"])
        f.binmode

        begin
          f.write(track.qr_code_image.download)
        rescue ActiveStorage::FileNotFoundError
          track.reload
          f.write(track.qr_code_image.download)
        end

        f.flush
        f.path
      end
    end

    # ── PDF attachment ──────────────────────────────────────────

    def attach_pdf_to_deck!(pdf_path)
      @deck.qr_cards_pdf.purge if @deck.qr_cards_pdf.attached?

      File.open(pdf_path, "rb") do |file|
        @deck.qr_cards_pdf.attach(
          io: file,
          filename: "deck_#{@deck.id}_qr_cards.pdf",
          content_type: "application/pdf"
        )
      end
    end

    # ── Cleanup ─────────────────────────────────────────────────

    def cleanup_tmp_files!(pdf_path)
      File.delete(pdf_path) if File.exist?(pdf_path)
    end

    def cleanup_cached_qr_png_tempfiles!
      @qr_png_temp_paths.each_value { |p| File.delete(p) if File.exist?(p) }
    end

    def default_url_options
      Rails.application.config.action_mailer.default_url_options ||
        { host: ENV.fetch("APP_HOST", "localhost"), port: ENV.fetch("APP_PORT", 3024) }
    end

    def notify_progress
      @on_progress&.call(@deck)
    end

    def sanitize_for_pdf(text)
      return "" if text.blank?
      text.to_s.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F]/, "")
    end

    def success(deck, pdf_path)
      Result.new(success: true, deck: deck, pdf_path: pdf_path, error: nil)
    end

    def failure(error)
      Result.new(success: false, deck: @deck, pdf_path: nil, error: error)
    end

    Result = Struct.new(:success, :deck, :pdf_path, :error, keyword_init: true) do
      def success? = success
      def failure? = !success
    end
  end
end
