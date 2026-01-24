# frozen_string_literal: true

module Games
  class ShowPresenter < ::ShowPresenter
    delegate :current_track, :current_track_index, :total_tracks, :tracks_played,
             :tracks_remaining, :progress_percentage, :tracks_revealed, :finished?,
             :completed?, :active?, :playlist, to: :object

    attr_reader :revealed

    def initialize(object:, revealed: false, decorator: nil)
      super(object: object, decorator: decorator)
      @revealed = revealed
    end

    def page_title
      t_context(".page_title", playlist_name: playlist.name)
    end

    def track_counter
      t_context(".track_counter", current: current_track_index + 1, total: total_tracks)
    end

    def progress_label
      t_context(".progress.played", count: tracks_played)
    end

    def remaining_label
      t_context(".progress.remaining", count: tracks_remaining)
    end

    def mystery_text
      t_context(".mystery.title")
    end

    def mystery_hint
      t_context(".mystery.hint")
    end

    def reveal_button_label
      t_context(".actions.reveal")
    end

    def skip_button_label
      t_context(".actions.skip")
    end

    def next_button_label
      t_context(".actions.next")
    end

    def abandon_button_label
      t_context(".actions.abandon")
    end

    def abandon_confirmation
      t_context(".confirmations.abandon")
    end

    def back_label
      t_context(".navigation.back")
    end

    def playing_from_label
      t_context(".playlist_info.playing_from")
    end

    def no_preview_message
      t_context(".no_preview")
    end

    # Finished game
    def finished_title
      completed? ? t_context(".finished.completed_title") : t_context(".finished.ended_title")
    end

    def finished_description
      t_context(".finished.description")
    end

    def stats_played_label
      t_context(".finished.stats.played")
    end

    def stats_revealed_label
      t_context(".finished.stats.revealed")
    end

    def stats_total_label
      t_context(".finished.stats.total")
    end

    def play_again_label
      t_context(".finished.actions.play_again")
    end

    def view_history_label
      t_context(".finished.actions.view_history")
    end
  end
end
