# frozen_string_literal: true

module Admin
  module Users
    class IndexPresenter < ::IndexPresenter
      def initialize(users:)
        super(collection: users, decorator: false)
      end

      def page_title
        t_context(".page_title")
      end

      def users
        decorated_collection
      end
    end
  end
end
