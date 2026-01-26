# frozen_string_literal: true

module Admin
  class ClassificationsController < BaseController
    before_action :set_classification

    def show
      @presenter = build_show_presenter
    end

    private

    def set_classification
      @classification = Classification.find(params[:id])
    end

    def build_show_presenter
      classification_values = @classification.classification_values.order(:sort_order, :value)
      Admin::Classifications::ShowPresenter.new(
        classification: @classification,
        classification_values: classification_values
      )
    end
  end
end
