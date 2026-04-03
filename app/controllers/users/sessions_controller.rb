# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout "unauthenticated"

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    redirect_to after_sign_out_path_for(resource_name), status: :see_other
  end

  protected

  def after_sign_in_path_for(resource)
    root_path
  end
end
