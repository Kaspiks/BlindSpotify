# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include PunditExtensions

  allow_browser versions: :modern

  # Authentication — restore when Google Stitch preview is done (unset STITCH_PUBLIC_PREVIEW).
  # before_action :authenticate_user!, unless: :devise_controller?
  before_action :authenticate_user!, unless: -> { devise_controller? || stitch_public_preview? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def render_action_with_errors(action, object:)
    flash_errors_for(object)
    render action
  end

  def sortable_params
    params.permit(:sort, :direction)
  end

  private

  # Set STITCH_PUBLIC_PREVIEW=true to allow anonymous access site-wide (Pundit skipped; guest user falls back to first User for forms).
  def stitch_public_preview?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("STITCH_PUBLIC_PREVIEW", "false"))
  end

  def authorize(record, query = nil, **kwargs)
    return if stitch_public_preview?

    super
  end

  def policy_scope(scope, policy_scope_class: nil)
    return scope.all if stitch_public_preview?

    super
  end

  def current_user
    return super unless stitch_public_preview?

    warden_user = warden.user(:user)
    warden_user.presence || User.order(:id).first
  end

  def flash_errors_for(object)
    flash.now[:alert] = error_message_list(object)
  end

  def error_message_list(object, **t_kwargs)
    view_context.message_list(
      object.errors.full_messages,
      default_message: t_context(".failure", **t_kwargs)
    )
  end

  def t_context(key, **kwargs)
    raise "translation key must be relative\nDid you mean?  .#{key}" unless key[0] == '.'

    i18n_scope = self.class.to_s.sub(/Controller\z/, '').underscore.tr('/', '.')

    I18n.t(
      "controllers.#{i18n_scope}.#{action_name}#{key}",
      default: :"controllers.global.#{action_name}#{key}",
      **kwargs
    )
  end

  def raise_routing_error(_error)
    raise ActionController::RoutingError, "Not Found"
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)
    redirect_back_or_to(root_path)
  end
end
