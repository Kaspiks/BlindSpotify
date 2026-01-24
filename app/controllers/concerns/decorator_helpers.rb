# frozen_string_literal: true

module DecoratorHelpers
  extend ActiveSupport::Concern

  DecorateError = Class.new(StandardError)

  class_methods do
    # rubocop:disable Naming/PredicateName
    def has_one_decorated(
      object_name,
      using: object_name,
      decorator_class_name: nil,
      expose: false,
      allow_nil: false
    )
      is_ivar = using.to_s[0] == "@"
      method_name = "decorated_#{object_name}"
      cache_ivar = "@#{method_name}"

      define_method(method_name) do
        return instance_variable_get(cache_ivar) if instance_variable_defined?(cache_ivar)

        object = is_ivar ? instance_variable_get(using) : send(using)

        if object.nil? && !allow_nil
          raise DecorateError, "unable to decorate nil value returned by `#{using}`\n" \
                               "did you forget to add `allow_nil: true`?"
        end

        decorated_object = object &&
          decorate(object, decorator: decorator_class_name&.constantize)

        instance_variable_set(cache_ivar, decorated_object)
      end

      private(method_name) unless expose
    end
    # rubocop:enable Naming/PredicateName

    # rubocop:disable Naming/PredicateName
    def has_many_decorated(
      object_name,
      using: object_name,
      decorator_class_name: nil,
      expose: false,
      cache_mode: :static
    )
      is_ivar = using.to_s[0] == "@"
      method_name = "decorated_#{object_name}"

      dynamic_cache_names = {}

      get_cache_ivar_name = proc do
        case cache_mode
        when :static
          "@#{method_name}"
        when :dynamic
          objects = is_ivar ? instance_variable_get(using) : send(using)
          dynamic_cache_names[objects] ||= "@#{method_name}_cache_#{dynamic_cache_names.size}"
        else
          raise "unknown cache mode #{cache_mode.inspect}"
        end
      end

      define_method(method_name) do
        cache_ivar = instance_exec(&get_cache_ivar_name)

        return instance_variable_get(cache_ivar) if instance_variable_defined?(cache_ivar)

        objects = is_ivar ? instance_variable_get(using) : send(using)

        raise DecorateError, "unable to decorate nil value returned by `#{using}`" if objects.nil?

        decorated_objects =
          decorate_collection(objects, decorator: decorator_class_name&.constantize)

        instance_variable_set(cache_ivar, decorated_objects)
      end

      private(method_name) unless expose
    end
    # rubocop:enable Naming/PredicateName
  end

  private

  def decorate(object, decorator: nil)
    DecorateService.call(object, decorator: decorator)
  end

  def decorate_collection(objects, decorator: nil)
    objects.map { |object| decorate(object, decorator: decorator) }
  end
end
