# frozen_string_literal: true

module Games
  class IndexPresenter < ::IndexPresenter
    def page_title
      t_context(".page_title")
    end

    def empty_state_title
      t_context(".empty_state.title")
    end

    def empty_state_description
      t_context(".empty_state.description")
    end

    def new_game_label
      t_context(".actions.new_game")
    end

    def status_label(status)
      t_context(".status.#{status}")
    end

    def status_class(status)
      case status.to_s
      when "active" then "bg-green-600/20 text-green-400"
      when "completed" then "bg-purple-600/20 text-purple-400"
      when "abandoned" then "bg-slate-600/20 text-slate-400"
      else "bg-slate-600/20 text-slate-400"
      end
    end
  end
end
