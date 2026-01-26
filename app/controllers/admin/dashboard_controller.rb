# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @presenter = build_index_presenter
    end

    private

    def build_index_presenter
      Admin::Dashboard::IndexPresenter.new
    end
  end
end
