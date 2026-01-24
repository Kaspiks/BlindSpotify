# frozen_string_literal: true

class DecorateService
  class << self
    def call(object, decorator: nil)
      decorator_class = decorator || decorator_for(object)
      decorator_class.new(object)
    end

    private

    def decorator_for(object)
      decorator_class_name = "#{object.class.name}Decorator"
      decorator_class_name.constantize
    rescue NameError
      raise ArgumentError, "Could not find decorator class #{decorator_class_name} for #{object.class.name}"
    end
  end
end
