# frozen_string_literal: true

module Admin
  class RolesController < BaseController
    before_action :set_role, only: [:show, :edit, :update, :destroy]

    def index
      @roles = Role.all.order(:name)
    end

    def show
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new(role_params)
      if @role.save
        redirect_to admin_roles_path, notice: "Role created successfully."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @role.update(role_params)
        redirect_to admin_role_path(@role), notice: "Role updated successfully."
      else
        render :edit
      end
    end

    def destroy
      if @role.users.any?
        redirect_to admin_roles_path, alert: "Cannot delete role that has users assigned."
      else
        @role.destroy
        redirect_to admin_roles_path, notice: "Role deleted successfully."
      end
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(:name, :description, permission_ids: [])
    end
  end
end
