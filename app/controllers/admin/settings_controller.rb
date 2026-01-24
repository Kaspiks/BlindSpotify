# frozen_string_literal: true

module Admin
  class SettingsController < BaseController
    before_action :set_setting, only: [:edit, :update]

    def index
      @settings = Setting.ordered
      @settings_by_group = @settings.group_by(&:group)
    end

    def edit
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: "Setting updated successfully."
      else
        render :edit
      end
    end

    private

    def set_setting
      @setting = Setting.find(params[:id])
    end

    def setting_params
      params.require(:setting).permit(:value)
    end
  end
end
