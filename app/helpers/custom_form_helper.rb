# frozen_string_literal: true

module CustomFormHelper
  def custom_form_for(object, *args, &block)
    options = args.extract_options!
    options[:builder] ||= CustomFormBuilder
    options[:html] ||= {}
    options[:html][:class] = [options[:html][:class], 'custom-form'].compact.join(' ')

    simple_form_for(object, *(args << options), &block)
  end

  def custom_fields_for(object, *args, &block)
    options = args.extract_options!
    options[:builder] ||= CustomFormBuilder

    simple_fields_for(object, *(args << options), &block)
  end
end
