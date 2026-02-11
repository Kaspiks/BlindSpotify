# frozen_string_literal: true

class DeckQrCodesGenerationJob < ApplicationJob
  queue_as :default

  def perform(aruco_deck_id)
    deck = ArucoDeck.find(aruco_deck_id)
    Rails.logger.info "[DeckQrCodesGenerationJob] Starting QR generation for deck #{aruco_deck_id}"

    result = QrCards::DeckGeneratorService.new(
      deck,
      on_progress: ->(d) { broadcast_progress(d) }
    ).call

    if result.success?
      Rails.logger.info "[DeckQrCodesGenerationJob] QR generation completed for deck #{aruco_deck_id}"
    else
      Rails.logger.error "[DeckQrCodesGenerationJob] QR generation failed for deck #{aruco_deck_id}: #{result.error}"
    end
  end

  private

  def broadcast_progress(deck)
    Rails.logger.debug "[DeckQrCodesGenerationJob] Broadcasting progress: #{deck.qr_generated_count}/#{deck.slots_count}"

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_aruco_deck_#{deck.id}",
      target: "aruco_deck_#{deck.id}_qr_progress",
      partial: "admin/aruco_decks/qr_progress",
      locals: { deck: deck }
    )
  end
end
