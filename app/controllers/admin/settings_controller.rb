# frozen_string_literal: true

module Admin
  class SettingsController < BaseController
    before_action :set_setting, only: [:edit, :update]

    def index
      @presenter = build_index_presenter
    end

    def edit
    end

    def update
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: t_context(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_setting
      @setting = Setting.find(params[:id])
    end

    def setting_params
      params.require(:setting).permit(:value)
    end

    def build_index_presenter
      settings = Setting.ordered
      Admin::Settings::IndexPresenter.new(settings: settings)
    end
  end
end
