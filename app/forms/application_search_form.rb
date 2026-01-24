# frozen_string_literal: true

class ApplicationSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def any_filters?
    self.class.attribute_names.any? { |attr| public_send(attr).present? }
  end

  def to_params
    self.class.attribute_names.each_with_object({}) do |attr, hash|
      value = public_send(attr)
      hash[attr] = value if value.present?
    end
  end

  def search_performed?
    any_filters?
  end
end
