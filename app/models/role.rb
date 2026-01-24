# frozen_string_literal: true

class Role < ApplicationRecord
  has_many :users, dependent: :nullify
  has_and_belongs_to_many :permissions

  validates :name, presence: true, uniqueness: true

  searchable_text_column :name

  sortable_by(
    columns: [:name, :created_at],
    defaults: { column: :name, direction: :asc }
  )

  def has_permission?(permission_code)
    permissions.exists?(code: permission_code)
  end

  def to_s
    name
  end
end
