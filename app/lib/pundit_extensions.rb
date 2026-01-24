# frozen_string_literal: true

module PunditExtensions
  def authorize_controller(record = nil)
    authorize(record, policy_class: controller_policy_class)
  end

  def controller_policy_class
    policy_class_prefix = self.class.to_s.sub(/Controller\z/, '').singularize

    "#{policy_class_prefix}Policy".constantize
  end

  def controller_policy_scope(scope)
    policy_scope_class = controller_policy_class.const_get("#{scope.model_name}Scope")

    policy_scope(scope, policy_scope_class: policy_scope_class)
  end
end
