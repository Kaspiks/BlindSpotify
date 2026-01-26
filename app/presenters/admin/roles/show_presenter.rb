# frozen_string_literal: true

module Admin
  module Roles
    class ShowPresenter < ::ShowPresenter
      def initialize(role:)
        super(object: role, decorator: false)
      end

      def page_title
        role.name
      end

      def role
        object
      end

      def name
        role.name
      end

      def description
        role.description
      end

      def has_description?
        role.description.present?
      end

      def permissions
        role.permissions
      end

      def permissions_count
        role.permissions.count
      end

      def users_count
        role.users.count
      end
    end
  end
end
