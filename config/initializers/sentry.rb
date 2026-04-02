# frozen_string_literal: true

# GlitchTip / Sentry error tracking. GlitchTip is Sentry API compatible.
# Set SENTRY_DSN in production (get from https://errors.blindjam.com after creating a project)
if Rails.env.production? && ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.environment = Rails.env
    config.release = ENV.fetch("SENTRY_RELEASE", nil)
    config.send_default_pii = false
  end
end
