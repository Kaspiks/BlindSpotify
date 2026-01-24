# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    layout "admin"

    helper_method :admin_navigation_presenter

    private

    def authorize_admin!
      # TODO: Implement proper admin authorization
      # For now, allow any authenticated user
      # raise Pundit::NotAuthorizedError unless current_user.admin?
    end

    def admin_navigation_presenter
      @admin_navigation_presenter ||= Admin::NavigationPresenter.new(
        view_context: view_context,
        controller_path: controller_path,
        user: current_user
      )
    end
  end
end
