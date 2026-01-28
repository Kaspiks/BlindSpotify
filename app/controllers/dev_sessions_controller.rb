# frozen_string_literal: true

# Development-only controller for quick user switching
# Allows signing in as any existing user without entering password
class DevSessionsController < ApplicationController
  skip_before_action :authenticate_user!

  before_action :ensure_development_environment

  def new
    @users = User.order(:email)
  end

  def create
    user = User.find(params[:user_id])
    sign_in(user)
    redirect_to root_path, notice: t_context(".sign_in_notice", user: user.display_name)
  end

  private

  def ensure_development_environment
    unless Rails.env.development?
      redirect_to root_path, alert: t_context(".dev_login_only_available_in_development")
    end
  end
end
