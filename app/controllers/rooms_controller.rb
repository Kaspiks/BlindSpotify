# frozen_string_literal: true

class RoomsController < ApplicationController
  include PresenterHelpers

  skip_before_action :authenticate_user!, only: [:show]

  presents_form :form, presenter_class: FormPresenter

  before_action :set_room, only: [:show]
  before_action :authorize_room_show, only: [:show]

  def show
    session[:host_room_code] = @room.code if current_user && @room.host?(current_user)
    # show_presenter built in show_presenter method below (needs current_user)
  end

  def show_presenter
    @show_presenter ||= Rooms::ShowPresenter.new(
      object: @room,
      current_user: current_user,
      decorator: RoomDecorator
    )
  end

  def new
    @room = Room.new
    @form = Rooms::Form.new(@room, host: current_user)
    authorize @room
    @presenter = FormPresenter.new(form: @form)
  end

  def create
    @room = Room.new
    @form = Rooms::Form.new(@room, host: current_user)
    authorize @room

    if @form.create(room_params)
      redirect_to room_join_path(@room.code), notice: t_context(".success")
    else
      @presenter = FormPresenter.new(form: @form)
      render_action_with_errors(:new, object: @form)
    end
  end

  private

  def set_room
    @room = Room.find_by!(code: params[:code])
  end

  def authorize_room_show
    authorize @room, :show?
  rescue Pundit::NotAuthorizedError
    redirect_to root_path, alert: t("pundit.room.show_not_authorized", default: "Room not found or closed.")
  end

  def room_params
    params.fetch(:rooms_form, {}).permit(:host_id)
  end
end
