# frozen_string_literal: true

SimpleForm.setup do |config|
  # Minimal wrapper - just wraps input without adding classes
  config.wrappers :default, tag: :div do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label
    b.use :input
    b.use :hint, wrap_with: { tag: :span }
    b.use :error, wrap_with: { tag: :span }
  end

  # Vertical form wrapper
  config.wrappers :vertical, tag: :div, class: 'mb-4' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium mb-1'
    b.use :input
    b.use :hint, wrap_with: { tag: :span, class: 'text-xs text-gray-500 mt-1 block' }
    b.use :error, wrap_with: { tag: :span, class: 'text-xs text-red-500 mt-1 block' }
  end

  # Tom Select enhanced select wrapper
  config.wrappers(
    :vertical_tom_select,
    tag: :div,
    class: 'mb-4'
  ) do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium mb-1'
    b.use :input
    b.use :hint, wrap_with: { tag: :span, class: 'text-xs text-slate-500 mt-1 block' }
    b.use :error, wrap_with: { tag: :span, class: 'text-xs text-red-500 mt-1 block' }
  end

  # Inline checkbox
  config.wrappers :inline_checkbox, tag: :div do |b|
    b.use :html5
    b.use :input
    b.use :label
  end

  config.default_wrapper = :default
  config.boolean_style = :inline
  config.button_class = nil
  config.error_notification_class = 'alert alert-danger'
  config.generate_additional_classes_for = []
  config.browser_validations = false
  config.boolean_label_class = nil

  # Don't add required asterisk
  config.label_text = ->(label, required, explicit_label) { label }

  # Map input types to their dedicated wrappers
  config.wrapper_mappings = {
    tom_select: :vertical_tom_select
  }
end

# Load custom inputs (app/inputs/ is not autoloaded by default)
Dir[Rails.root.join("app/inputs/**/*.rb")].each { |f| require f }
