# frozen_string_literal: true

class GamesController < ApplicationController
  include PresenterHelpers

  before_action :set_game, only: %i[show next_track reveal abandon]

  presents_index :games, presenter_class: Games::IndexPresenter, decorator: false
  presents_show :game, presenter_class: Games::ShowPresenter, decorator: false
  presents_form :form, presenter_class: Games::FormPresenter

  def index
    @games = policy_scope(Game).recent.includes(:playlist)
    authorize Game
  end

  def new
    @game = current_user.games.build
    @form = Games::Form.new(@game)
    authorize @game
  end

  def create
    @game = current_user.games.build
    @form = Games::Form.new(@game)
    authorize @game

    if @form.create(game_params)
      redirect_to game_path(@game), notice: t_context(".success")
    else
      render_action_with_errors(:new, object: @form)
    end
  end

  def show
    authorize @game
    @revealed = params[:revealed] == "true"
  end

  def show_presenter
    @show_presenter ||= Games::ShowPresenter.new(
      object: @game,
      revealed: @revealed || false
    )
  end

  def next_track
    authorize @game
    @game.next_track!
    @revealed = false

    if @game.finished?
      redirect_to game_path(@game), notice: t_context(".completed")
    else
      respond_to do |format|
        format.html { redirect_to game_path(@game) }
        format.turbo_stream { render_turbo_stream_update }
      end
    end
  end

  def reveal
    authorize @game
    @game.reveal_current!
    @revealed = true

    respond_to do |format|
      format.html { redirect_to game_path(@game, revealed: true) }
      format.turbo_stream { render_turbo_stream_update }
    end
  end

  def abandon
    authorize @game
    @game.abandon!
    redirect_to games_path, notice: t_context(".success")
  end

  private

  def set_game
    @game = policy_scope(Game).find(params[:id])
  end

  def game_params
    params.require(:game).permit(:playlist_id)
  end

  def render_turbo_stream_update
    render turbo_stream: [
      turbo_stream.replace(
        "game-header",
        partial: "games/header",
        locals: { game: @game, presenter: show_presenter }
      ),
      turbo_stream.replace(
        "game-progress",
        partial: "games/progress_bar",
        locals: { presenter: show_presenter }
      ),
      turbo_stream.replace(
        "game-area",
        partial: "games/game_area",
        locals: { game: @game, revealed: @revealed, presenter: show_presenter }
      )
    ]
  end
end
