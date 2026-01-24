# frozen_string_literal: true

class Permission < ApplicationRecord
  has_and_belongs_to_many :roles

  validates :code, presence: true, uniqueness: true
  validates :description, presence: true

  scope :ordered, -> { order(:code) }

  searchable_text_column :code
  searchable_text_column :description

  def to_s
    code
  end
end
