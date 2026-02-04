# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @presenter = build_index_presenter
    end

    def show
      @presenter = build_show_presenter
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t_context(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: t_context(".success")
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:admin, :role_id)
    end

    def build_index_presenter
      users = User.includes(:role).order(:created_at)
      Admin::Users::IndexPresenter.new(users: users)
    end

    def build_show_presenter
      Admin::Users::ShowPresenter.new(user: @user)
    end
  end
end
