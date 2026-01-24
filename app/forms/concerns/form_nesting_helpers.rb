# frozen_string_literal: true

module FormNestingHelpers
  extend ActiveSupport::Concern

  class_methods do
    # Define a nested form association (has_one style)
    #
    # == Examples
    #
    #   nested_form :address, form_class: AddressForm
    #
    def nested_form(name, form_class:, build_with: nil)
      attr_reader name

      define_method("#{name}=") do |attributes|
        nested = instance_variable_get("@#{name}")
        nested ||= send("build_#{name}")
        nested.assign_attributes(attributes) if attributes.present?
        nested
      end

      define_method("build_#{name}") do |*args|
        form = if build_with
                 instance_exec(*args, &build_with)
               else
                 form_class.new(*args)
               end
        instance_variable_set("@#{name}", form)
      end

      define_method("#{name}_attributes=") do |attributes|
        send("#{name}=", attributes)
      end
    end

    # Define a nested form collection (has_many style)
    #
    # == Examples
    #
    #   nested_forms :line_items, form_class: LineItemForm
    #
    def nested_forms(name, form_class:, build_with: nil, reject_if: nil)
      singular_name = name.to_s.singularize

      define_method(name) do
        instance_variable_get("@#{name}") || instance_variable_set("@#{name}", [])
      end

      define_method("#{name}=") do |collection|
        instance_variable_set("@#{name}", collection || [])
      end

      define_method("build_#{singular_name}") do |*args|
        form = if build_with
                 instance_exec(*args, &build_with)
               else
                 form_class.new(*args)
               end
        send(name) << form
        form
      end

      define_method("#{name}_attributes=") do |attributes_collection|
        return if attributes_collection.blank?

        items = attributes_collection.is_a?(Hash) ? attributes_collection.values : attributes_collection

        items.each do |attributes|
          next if attributes.blank?
          next if reject_if && instance_exec(attributes, &reject_if)

          if attributes["_destroy"].present? || attributes[:_destroy].present?
            next
          end

          form = send("build_#{singular_name}")
          form.assign_attributes(attributes.except("_destroy", :_destroy))
        end
      end
    end
  end

  def collect_nested_errors(association_name)
    nested = send(association_name)
    return if nested.blank?

    items = nested.is_a?(Array) ? nested : [nested]

    items.each_with_index do |item, index|
      next if item.errors.blank?

      item.errors.each do |error|
        key = items.size > 1 ? "#{association_name}[#{index}].#{error.attribute}" : "#{association_name}.#{error.attribute}"
        errors.add(key.to_sym, error.message)
      end
    end
  end
end
