# frozen_string_literal: true

class PlaylistsController < ApplicationController
  include PresenterHelpers

  before_action :set_playlist, only: %i[show destroy import status]

  presents_index :playlists, presenter_class: Playlists::IndexPresenter, decorator: false
  presents_form :form, presenter_class: Playlists::FormPresenter

  def index
    @playlists = policy_scope(Playlist).includes(:genre, :tracks).order(created_at: :desc)
    authorize Playlist
  end

  def show
    authorize @playlist
    @presenter = Playlists::ShowPresenter.new(playlist: @playlist)
  end

  def new
    @playlist = current_user.playlists.build
    @form = Playlists::Form.new(@playlist)
    authorize @playlist
  end

  def create
    @playlist = current_user.playlists.build
    @form = Playlists::Form.new(@playlist)
    authorize @playlist

    if @form.create(playlist_params)
      notice = @form.should_import? ? t_context(".success_importing") : t_context(".success")
      redirect_to @playlist, notice: notice
    else
      render_action_with_errors(:new, object: @form)
    end
  end

  def destroy
    authorize @playlist
    @playlist.destroy
    redirect_to playlists_path, notice: t_context(".success")
  end

  def import
    authorize @playlist
    # Clear existing tracks to get fresh data (including new preview URLs)
    @playlist.tracks.destroy_all
    @playlist.update!(import_status: "pending", imported_tracks_count: 0, tracks_count: 0, import_error: nil)
    PlaylistImportJob.perform_later(@playlist.id)
    redirect_to @playlist, notice: t_context(".success")
  end

  def status
    authorize @playlist, :show?
    render json: {
      status: @playlist.import_status,
      imported_tracks_count: @playlist.imported_tracks_count,
      tracks_count: @playlist.tracks_count,
      progress: @playlist.import_progress_percentage
    }
  end

  private

  def set_playlist
    @playlist = policy_scope(Playlist).find(params[:id])
  end

  def playlist_params
    params.require(:playlists_form).permit(:name, :genre_id, :description, :deezer_url)
  end
end
