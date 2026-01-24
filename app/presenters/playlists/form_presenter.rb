# frozen_string_literal: true

module Playlists
  class FormPresenter < ::FormPresenter
    delegate :available_genres, to: :form

    def page_title
      form.persisted? ? t_context(".edit_title") : t_context(".new_title")
    end

    def page_description
      t_context(".description")
    end

    def submit_label
      form.persisted? ? t_context(".actions.update") : t_context(".actions.create")
    end

    def cancel_label
      t_context(".actions.cancel")
    end

    def deezer_url_hint
      t_context(".hints.deezer_url")
    end

    def genre_hint
      t_context(".hints.genre")
    end
  end
end
