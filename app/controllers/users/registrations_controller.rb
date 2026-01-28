# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout "unauthenticated"

  protected

  def after_sign_up_path_for(resource)
    root_path
  end
end
