# frozen_string_literal: true

class FormPresenter < ApplicationPresenter
  attr_reader :form

  def initialize(form:)
    super()
    @form = form
  end
end
