# frozen_string_literal: true

class ClassificationValue < ApplicationRecord
  belongs_to :classification

  validates :value, presence: true
  validates :value, uniqueness: { scope: :classification_id }

  scope :active, -> { where(active: true) }
  scope :for_classification, ->(code) { joins(:classification).where(classifications: { code: code }) }

  searchable_text_column :value

  sortable_by(
    columns: [:value, :sort_order, :created_at],
    defaults: { column: :sort_order, direction: :asc }
  )

  def to_s
    value
  end
end
