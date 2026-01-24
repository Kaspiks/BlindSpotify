# frozen_string_literal: true

module Spec
  module Support
    module DecoratorHelpers
      def decorated_instance_double(object_class, *args)
        decorator_class = "#{object_class}Decorator".constantize
        object = instance_double(object_class, *args)

        decorator_class.new(object)
      end
    end
  end
end
