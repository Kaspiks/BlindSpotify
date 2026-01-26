# frozen_string_literal: true

module Admin
  module Playlists
    class ShowPresenter < ::ShowPresenter
      attr_reader :tracks

      def initialize(playlist:, tracks:)
        super(object: playlist, decorator: false)
        @tracks = tracks
      end

      def page_title
        playlist.name
      end

      def playlist
        object
      end

      def can_generate_qr_codes?
        playlist.can_generate_qr_codes?
      end

      def qr_completed?
        playlist.qr_completed?
      end

      def qr_generating?
        playlist.qr_generating?
      end

      def has_image?
        playlist.image_url.present?
      end

      def has_genre?
        playlist.genre.present?
      end

      def genre_name
        playlist.genre&.value
      end

      def owner_name
        playlist.user.display_name
      end

      def tracks_count_text
        ActionController::Base.helpers.pluralize(playlist.tracks_count, "track")
      end
    end
  end
end
