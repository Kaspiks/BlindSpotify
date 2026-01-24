# frozen_string_literal: true

module Games
  class FormPresenter < ::FormPresenter
    delegate :available_playlists_by_genre, to: :form

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

    def import_playlist_label
      t_context(".empty_state.import_action")
    end

    def playlist_count_label(count)
      t_context(".playlist_count", count: count)
    end

    def tracks_count_label(count)
      t_context(".tracks_count", count: count)
    end

    def play_button_label
      t_context(".actions.play")
    end

    def uncategorized_label
      t_context(".uncategorized")
    end
  end
end
