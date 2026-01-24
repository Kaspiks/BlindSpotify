# frozen_string_literal: true

class Classification < ApplicationRecord
  has_many :classification_values, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  searchable_text_column :name
  searchable_text_column :code

  sortable_by(
    columns: [:name, :code, :created_at],
    defaults: { column: :name, direction: :asc }
  )

  def to_s
    name
  end
end
