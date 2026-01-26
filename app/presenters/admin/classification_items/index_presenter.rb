# frozen_string_literal: true

module Admin
  module ClassificationItems
    class IndexPresenter < ::IndexPresenter
      def initialize(classifications:)
        super(collection: classifications, decorator: false)
      end

      def page_title
        t_context(".page_title")
      end

      def classifications
        decorated_collection
      end
    end
  end
end
