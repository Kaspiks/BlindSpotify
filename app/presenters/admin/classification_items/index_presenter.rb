# frozen_string_literal: true

module Admin
  module ClassificationItems
    class IndexPresenter < ::IndexPresenter
      ClassificationItem = Struct.new(:title, :url)

      def initialize(classifications:)
        super(collection: classifications, decorator: ::ClassificationDecorator)
      end

      def page_title
        t_context(".page_title")
      end

      def classifications
        decorated_collection
      end

      private

      def classification_items
        decorated_collection.map do |classification|
          ClassificationItem.new(
            classification.title,
            resolved_classification_path(classification)
          )
        end
      end

      def resolved_classification_path(classification)
        default_path = url_helpers.configurations_classification_path(classification)
        path_method = "configurations_#{classification.code}_path"

        return default_path if classification.code.blank?
        return default_path unless url_helpers.respond_to?(path_method)

        url_helpers.public_send(path_method)
      end

      # def custom_classification_items
      #   [
      #     ClassificationItem.new(
      #       t_context('.resource_types'),
      #       url_helpers.admin_resource_types_path
      #     ),
      #     ClassificationItem.new(
      #       t_context('.grant_types'),
      #       url_helpers.admin_grant_types_path
      #     )
      #   ]
      # end
    end
  end
end
