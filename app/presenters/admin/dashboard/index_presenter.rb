# frozen_string_literal: true

module Admin
  module Dashboard
    class IndexPresenter < ::ApplicationPresenter
      def initialize
        super()
      end

      def page_title
        t_context(".page_title")
      end

      def total_users
        User.count
      end

      def total_playlists
        Playlist.count
      end

      def total_tracks
        Track.count
      end

      def total_games
        Game.count
      end

      def completed_playlists
        Playlist.where(import_status: "completed").count
      end

      def playlists_with_qr
        Playlist.where(qr_status: "completed").count
      end
    end
  end
end
