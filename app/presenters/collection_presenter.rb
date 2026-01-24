# frozen_string_literal: true

class CollectionPresenter < ApplicationPresenter
  attr_reader :decorated_collection

  def initialize(
    collection,
    value_method: :id,
    custom_properties_method: :collection_custom_properties,
    label_method: nil,
    decorator: nil,
    sorter: nil,
    limit: nil
  )
    super()
    @sorter = sorter
    @collection = collection
    @decorator = decorator
    @decorated_collection =
      if decorator == false
        @collection
      else
        decorate_collection(@collection, decorator: @decorator)
      end
    @custom_properties_method = custom_properties_method
    @value_method = value_method
    @label_method = label_method
    @limit = limit
  end

  def items
    collection = sorted_collection
    collection = collection.slice(0, @limit) unless @limit.nil?
    collection.map do |item|
      {
        value: item.public_send(@value_method),
        label: get_label(item),
        **{ customProperties: item_custom_properties(item) }.compact
      }
    end
  end

  def items_for_select
    collection = sorted_collection
    collection = sorted_collection.slice(0, @limit) unless @limit.nil?
    collection.map do |item|
      [
        get_label(item),
        item.public_send(@value_method),
        { data: { "custom-properties": item_custom_properties(item) }.compact }
      ]
    end
  end

  private

  def get_label(item)
    label_method = @label_method.presence
    label_method ||= :collection_title if item.respond_to?(:collection_title)
    label_method ||= :title if item.respond_to?(:title)
    label_method ||= :name if item.respond_to?(:name)
    label_method ||= :to_s
    item.public_send(label_method)
  end

  def item_custom_properties(item)
    return unless @custom_properties_method
    return unless item.respond_to?(@custom_properties_method)

    item.public_send(@custom_properties_method).to_h
  end

  def sorted_collection
    return decorated_collection unless @sorter

    decorated_collection.sort_by do |item|
      @sorter.sort_key(get_label(item))
    end
  end
end
