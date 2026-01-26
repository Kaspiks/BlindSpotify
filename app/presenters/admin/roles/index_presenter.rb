# frozen_string_literal: true

module Admin
  module Roles
    class IndexPresenter < ::IndexPresenter
      def initialize(roles:)
        super(collection: roles, decorator: false)
      end

      def page_title
        t_context(".page_title")
      end

      def roles
        decorated_collection
      end
    end
  end
end
