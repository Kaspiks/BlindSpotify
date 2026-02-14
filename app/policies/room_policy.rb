# frozen_string_literal: true

class RoomPolicy < ApplicationPolicy
  def show?
    record.present? && record.active?
  end

  def new?
    true
  end

  def create?
    true
  end

  def play_track?
    record.present? && record.host?(user) && record.active?
  end

  def reveal?
    record.present? && record.host?(user) && record.active?
  end

  def next?
    record.present? && record.host?(user) && record.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.where(host_id: user.id)
    end
  end
end
