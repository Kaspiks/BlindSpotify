# frozen_string_literal: true

class ApplicationForm
  include ActiveModel::Model
  include DecoratorHelpers
  include FormFieldHelpers
  include FormNestingHelpers

  class << self
    private

    def validates_associated(*associations, form_only: false, **config)
      validate(**config) do |form|
        associations.each do |association|
          associated = form.send(association)

          validate_method = form_only ? :valid? : :form_and_object_valid?

          validation_runner = proc do |item|
            is_form = item.respond_to?(validate_method)
            context = form.validation_context

            is_form ? item.public_send(validate_method, context) : item.valid?(context)
          end

          is_valid =
            if associated.is_a?(Array)
              associated.map(&validation_runner).all? { |validity| validity }
            else
              associated.yield_self(&validation_runner)
            end

          form.errors.add(association.to_sym, :invalid) unless is_valid
        end
      end
    end
  end
end
