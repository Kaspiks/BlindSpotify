# frozen_string_literal: true

module Admin
  module ArucoDecks
    class ShowPresenter < ::ShowPresenter
      attr_reader :aruco_deck

      def initialize(aruco_deck:)
        super(object: aruco_deck, decorator: false)
        @aruco_deck = aruco_deck
      end

      def page_title
        aruco_deck.name
      end

      def source_playlist
        aruco_deck.playlist
      end

      def slots
        aruco_deck.aruco_deck_slots.includes(track: :playlist).to_a
      end

      def has_slots?
        slots.any?
      end

      def playlists_for_assign
        Playlist.where(import_status: "completed").where("tracks_count >= ?", 1).order(:name)
      end
    end
  end
end
