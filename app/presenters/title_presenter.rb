# frozen_string_literal: true

class TitlePresenter < ApplicationPresenter
  def initialize(object, attribute: :title)
    super()
    @object = object
    @attribute = attribute
  end

  def title_with_state
    @object.active? ? title : "#{title} (#{t_context('.inactive')})"
  end

  private

  def title
    @object.public_send(@attribute)
  end
end
