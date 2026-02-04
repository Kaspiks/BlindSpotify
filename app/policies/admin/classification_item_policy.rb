# frozen_string_literal: true

module Admin
  class ClassificationItemPolicy < ApplicationPolicy
    def index?
      user&.admin? || user&.has_permission?("configurations/classifications/manage")
    end
  end
end
