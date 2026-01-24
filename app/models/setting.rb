# frozen_string_literal: true

class Setting < ApplicationRecord
  VALID_VALUE_TYPES = %w[string integer boolean text].freeze

  validates :key, presence: true, uniqueness: true
  validates :value_type, presence: true, inclusion: { in: VALID_VALUE_TYPES }

  scope :ordered, -> { order(:group, :key) }
  scope :in_group, ->(group) { where(group: group) }

  searchable_text_column :key
  searchable_text_column :description

  sortable_by(
    columns: [:key, :group, :created_at],
    defaults: { column: :key, direction: :asc }
  )

  def typed_value
    case value_type
    when "integer"
      value.to_i
    when "boolean"
      ActiveModel::Type::Boolean.new.cast(value)
    else
      value
    end
  end

  def typed_value=(new_value)
    self.value = new_value.to_s
  end

  class << self
    def get(key, default: nil)
      setting = find_by(key: key)
      setting&.typed_value || default
    end

    def set(key, value)
      setting = find_or_initialize_by(key: key)
      setting.typed_value = value
      setting.save!
    end
  end

  def to_s
    key
  end
end
