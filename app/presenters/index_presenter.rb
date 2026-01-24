# frozen_string_literal: true

class IndexPresenter < ApplicationPresenter
  attr_reader :collection, :decorated_collection

  def initialize(collection:, decorator: nil)
    super()
    @collection = collection
    @decorator = decorator
    @decorated_collection =
      if decorator == false
        collection
      else
        decorate_collection(collection, decorator: decorator)
      end
  end

  def page_title
    nil
  end

  def collection_for_select(**options)
    CollectionPresenter.new(@collection, **options)
  end
end
