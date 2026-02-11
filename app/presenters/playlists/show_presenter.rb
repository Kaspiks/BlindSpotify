# frozen_string_literal: true

module Playlists
  class ShowPresenter < ::ShowPresenter
    def initialize(playlist:, tracks: nil, **options)
      super(object: playlist, **options)
      @playlist = playlist
      @tracks = tracks
    end

    attr_reader :playlist

    delegate :tracks, :import_status, :import_progress_percentage, :pending?,
             :importing?, :completed?, :failed?, :genre, :deezer_url, :image_url,
             :tracks_count, :imported_tracks_count, to: :playlist

    def page_title
      playlist.name
    end

    def back_label
      t_context(".navigation.back")
    end

    def view_on_deezer_label
      t_context(".actions.view_on_deezer")
    end

    def delete_label
      t_context(".actions.delete")
    end

    def delete_confirmation
      t_context(".confirmations.delete")
    end

    def reimport_label
      t_context(".actions.reimport")
    end

    def tracks_header
      t_context(".tracks.header", count: sorted_tracks.size)
    end

    def sorted_tracks
      base = @tracks || playlist.tracks
      return base if base.is_a?(Array)

      tracks_table = Track.arel_table
      preview_url = tracks_table[:preview_url]
      position = tracks_table[:position]
      id = tracks_table[:id]

      preview_url_is_null = preview_url.eq(nil)
      sort_key = Arel::Nodes::Case.new
        .when(preview_url_is_null, 1)
        .else(0)

      base
        .unscope(:order)
        .reorder(Arel::Nodes::Ascending.new(sort_key))
        .order(position, id)
    end

    def empty_tracks_message
      t_context(".tracks.empty")
    end

    # Import status messages
    def import_status_title
      t_context(".import.status.#{import_status}.title")
    end

    def import_status_description
      t_context(".import.status.#{import_status}.description")
    end

    def import_progress_label
      t_context(".import.progress", imported: imported_tracks_count, total: tracks_count)
    end
  end
end
