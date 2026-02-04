# frozen_string_literal: true

module Admin
  class RolesController < BaseController
    before_action :set_role, only: [:show, :edit, :update, :destroy]

    def index
      @presenter = build_index_presenter
    end

    def show
      @presenter = build_show_presenter
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new(role_params)
      if @role.save
        redirect_to admin_roles_path, notice: t_context(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @role.update(role_params)
        redirect_to admin_role_path(@role), notice: t_context(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @role.users.any?
        redirect_to admin_roles_path, alert: t_context(".cannot_delete")
      else
        @role.destroy
        redirect_to admin_roles_path, notice: t_context(".success")
      end
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(:name, :description, permission_ids: [])
    end

    def build_index_presenter
      roles = Role.includes(:permissions, :users).order(:name)
      Admin::Roles::IndexPresenter.new(roles: roles)
    end

    def build_show_presenter
      Admin::Roles::ShowPresenter.new(role: @role)
    end
  end
end
