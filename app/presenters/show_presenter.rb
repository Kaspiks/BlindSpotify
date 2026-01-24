# frozen_string_literal: true

class ShowPresenter < ApplicationPresenter
  attr_reader :object

  def initialize(object:, decorator: nil)
    super()
    @object = object
    @decorator_class = decorator
  end

  def page_title
    return nil unless object.respond_to?(:title) || object.respond_to?(:name)

    object.respond_to?(:title) ? object.title : object.name
  end

  def decorated_object
    @decorated_object ||=
      if @decorator_class == false
        object
      elsif @decorator_class
        decorate(object, decorator: @decorator_class)
      else
        decorate(object)
      end
  end
end
