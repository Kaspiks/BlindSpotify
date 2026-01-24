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

# == Schema Information
#
# Table name: classifications
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  code        :string           not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_classifications_on_code  (code) UNIQUE
#  index_classifications_on_name  (name) UNIQUE
#
