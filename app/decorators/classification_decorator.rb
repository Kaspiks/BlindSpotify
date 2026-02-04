# frozen_string_literal: true

class ClassificationDecorator < ApplicationDecorator
  def breadcrumb_title
    title
  end

  def title
    t_context(".#{code}")
  end
end
