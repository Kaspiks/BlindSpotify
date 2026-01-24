# frozen_string_literal: true

module Playlists
  class IndexPresenter < ::IndexPresenter
    def page_title
      t_context(".page_title")
    end

    def page_description
      t_context(".page_description")
    end

    def empty_state_title
      t_context(".empty_state.title")
    end

    def empty_state_description
      t_context(".empty_state.description")
    end

    def new_playlist_label
      t_context(".actions.new_playlist")
    end

    def tracks_count_label(count)
      t_context(".tracks_count", count: count)
    end

    def import_status_label(status)
      t_context(".import_status.#{status}")
    end
  end
end
