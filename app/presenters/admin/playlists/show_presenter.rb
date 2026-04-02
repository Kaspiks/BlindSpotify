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

      def playlist_qr_code_text
        tracks_w_years = tracks.where.not(release_year: nil)

        base_text = 'Which of these songs have incorrect release years?'

        prompt_text = "Return year corrections by song = year in a json format. Such as: {[song: <title>, year: <year> ]}"
        tracks_n_years = tracks_w_years.map do |track|
          [track.title, track.release_year].join(' - ')
        end.join("\n")

        [base_text, tracks_n_years, prompt_text].join("\n")
      end

      # Encoded for use in HTML data attributes (newlines → &#10;) so clipboard copy works.
      def playlist_qr_code_text_for_clipboard
        playlist_qr_code_text.gsub("\n", "&#10;").html_safe
      end

      def share_label
        t_context(".share_label")
      end

      def copied_label
        t_context(".copied_label")
      end

      def copy_button_label
        t_context(".copy_button_label")
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
