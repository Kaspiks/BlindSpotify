# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  def admin?
    user&.admin?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  # Check if user has a specific permission
  # Usage: can?("users.update") or can?(:update)
  def can?(permission)
    return false unless user

    # If it's a symbol, derive the permission code from the record class
    permission_code = if permission.is_a?(Symbol)
      resource_name = record.is_a?(Class) ? record.name.underscore.pluralize : record.class.name.underscore.pluralize
      "#{resource_name}.#{permission}"
    else
      permission.to_s
    end

    user.has_permission?(permission_code)
  end

  # Check if user can access admin area
  def admin_access?
    user&.admin? || can?("dashboard.view")
  end
end
