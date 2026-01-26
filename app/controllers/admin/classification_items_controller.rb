# frozen_string_literal: true

module Admin
  class ClassificationItemsController < BaseController
    def index
      @presenter = build_index_presenter
    end

    private

    def build_index_presenter
      classifications = Classification.includes(:classification_values).order(:name)
      Admin::ClassificationItems::IndexPresenter.new(classifications: classifications)
    end
  end
end
