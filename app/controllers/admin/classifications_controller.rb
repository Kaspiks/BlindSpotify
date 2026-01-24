# frozen_string_literal: true

module Admin
  class ClassificationsController < BaseController
    before_action :set_classification

    def show
      @classification_values = @classification.classification_values.order(:sort_order, :value)
    end

    private

    def set_classification
      @classification = Classification.find(params[:id])
    end
  end
end
