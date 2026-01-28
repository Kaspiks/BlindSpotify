# frozen_string_literal: true

# OmniAuth configuration
# Currently not using OmniAuth providers (using email/password authentication)
# Keeping this file for potential future OAuth integration

OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [:post]

# Enable test mode in test environment
OmniAuth.config.test_mode = true if Rails.env.test?
