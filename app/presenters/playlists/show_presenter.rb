# frozen_string_literal: true

module Playlists
  class ShowPresenter < ::ShowPresenter
    delegate :tracks, :import_status, :import_progress_percentage, :pending?,
             :importing?, :completed?, :failed?, :genre, :deezer_url, :image_url,
             :tracks_count, :imported_tracks_count, to: :object

    def page_title
      object.name
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
      t_context(".tracks.header", count: tracks.size)
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
