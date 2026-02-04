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

  # Human-readable label from decorators.permission I18n structure
  # Falls back to description if no decorator key is defined
  def label
    i18n_key = "decorators.permission.#{code.tr('/', '.')}"
    I18n.t(i18n_key, default: description)
  end
end

# == Schema Information
#
# Table name: permissions
#
#  id          :bigint           not null, primary key
#  code        :string           not null
#  description :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_permissions_on_code  (code) UNIQUE
#
