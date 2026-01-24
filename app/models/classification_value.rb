# frozen_string_literal: true

class ClassificationValue < ApplicationRecord
  belongs_to :classification

  validates :value, presence: true
  validates :value, uniqueness: { scope: :classification_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :value) }
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

# == Schema Information
#
# Table name: classification_values
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  description       :text
#  sort_order        :integer          default(0), not null
#  value             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  classification_id :bigint           not null
#
# Indexes
#
#  index_classification_values_on_classification_id            (classification_id)
#  index_classification_values_on_classification_id_and_value  (classification_id,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (classification_id => classifications.id)
#
