# frozen_string_literal: true

module Admin
  module Users
    class ShowPresenter < ::ShowPresenter
      def initialize(user:)
        super(object: user, decorator: false)
      end

      def page_title
        user.display_name
      end

      def user
        object
      end

      def display_name
        user.display_name
      end

      def email
        user.email
      end

      def role_name
        user.role&.name || "No role"
      end

      def has_role?
        user.role.present?
      end

      def admin?
        user.admin?
      end

      def created_at
        user.created_at
      end

      def provider
        user.provider&.titleize || "Unknown"
      end
    end
  end
end
