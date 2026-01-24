# frozen_string_literal: true

module PresenterHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :index_presenter, :show_presenter, :form_presenter, :navigation_presenter
  end

  class_methods do
    def presents_index(collection_name, presenter_class: IndexPresenter, decorator: nil)
      define_method(:index_presenter) do
        @index_presenter ||= presenter_class.new(
          collection: instance_variable_get("@#{collection_name}"),
          decorator: decorator
        )
      end
    end

    def presents_show(object_name, presenter_class: ShowPresenter, decorator: nil)
      define_method(:show_presenter) do
        @show_presenter ||= presenter_class.new(
          object: instance_variable_get("@#{object_name}"),
          decorator: decorator
        )
      end
    end

    def presents_form(form_name, presenter_class: FormPresenter)
      define_method(:form_presenter) do
        @form_presenter ||= presenter_class.new(
          form: instance_variable_get("@#{form_name}")
        )
      end
    end
  end

  private

  def index_presenter
    raise NotImplementedError, "Define index_presenter using `presents_index` or implement in controller"
  end

  def show_presenter
    raise NotImplementedError, "Define show_presenter using `presents_show` or implement in controller"
  end

  def form_presenter
    raise NotImplementedError, "Define form_presenter using `presents_form` or implement in controller"
  end

  def navigation_presenter
    @navigation_presenter ||= NavigationPresenter.new(
      view_context: view_context,
      controller_path: controller_path,
      user: current_user_for_navigation
    )
  end

  def current_user_for_navigation
    respond_to?(:current_user) ? current_user : nil
  end
end
