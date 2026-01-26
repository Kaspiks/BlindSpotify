# frozen_string_literal: true

module Admin
  module Classifications
    class ShowPresenter < ::ShowPresenter
      attr_reader :classification_values

      def initialize(classification:, classification_values:)
        super(object: classification, decorator: false)
        @classification_values = classification_values
      end

      def page_title
        classification.name
      end

      def classification
        object
      end

      def name
        classification.name
      end

      def code
        classification.code
      end

      def description
        classification.description
      end

      def has_description?
        classification.description.present?
      end

      def values_count
        classification_values.count
      end

      def active?
        classification.active?
      end
    end
  end
end
