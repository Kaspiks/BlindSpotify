# frozen_string_literal: true

class GamePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner?
  end

  def new?
    create?
  end

  def create?
    user.present?
  end

  def next_track?
    owner? && record.active?
  end

  def reveal?
    owner? && record.active?
  end

  def abandon?
    owner? && record.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
