# frozen_string_literal: true

module Admin
  class ClassificationItemsController < BaseController
    def index
      @classifications = Classification.all.order(:name)
    end
  end
end
