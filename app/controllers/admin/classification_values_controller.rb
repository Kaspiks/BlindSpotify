# frozen_string_literal: true

module Admin
  class ClassificationValuesController < BaseController
    before_action :set_classification
    before_action :set_classification_value, only: [:edit, :update]

    def new
      @classification_value = @classification.classification_values.build
    end

    def create
      @classification_value = @classification.classification_values.build(classification_value_params)
      if @classification_value.save
        redirect_to admin_classification_path(@classification), notice: "Value created successfully."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @classification_value.update(classification_value_params)
        redirect_to admin_classification_path(@classification), notice: "Value updated successfully."
      else
        render :edit
      end
    end

    private

    def set_classification
      @classification = Classification.find(params[:classification_id])
    end

    def set_classification_value
      @classification_value = @classification.classification_values.find(params[:id])
    end

    def classification_value_params
      params.require(:classification_value).permit(:value, :description, :sort_order, :active)
    end
  end
end
