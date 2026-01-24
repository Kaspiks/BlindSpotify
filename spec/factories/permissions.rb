# frozen_string_literal: true
FactoryBot.define do
  factory :permission do
    sequence(:code) { |n| "permission.#{n}" }
    description { "A sample permission" }
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
