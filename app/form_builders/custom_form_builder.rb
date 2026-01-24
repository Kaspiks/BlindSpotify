# frozen_string_literal: true

class CustomFormBuilder < SimpleForm::FormBuilder
  # Default wrapper for auth forms
  def input(attribute_name, options = {}, &block)
    options[:wrapper] ||= :auth_field
    super(attribute_name, options, &block)
  end

  # Submit button with themed styling
  def submit(value = nil, options = {})
    value ||= submit_default_value
    options[:class] = [
      "w-full py-3.5 px-4 rounded-xl font-semibold text-white",
      "transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98]",
      "cursor-pointer shadow-lg",
      "bg-gradient-to-r from-green-500 to-green-600",
      "hover:from-green-400 hover:to-green-500",
      "shadow-green-500/30",
      options[:class]
    ].compact.join(" ")

    @template.content_tag(:div) do
      super(value, options)
    end
  end
end
