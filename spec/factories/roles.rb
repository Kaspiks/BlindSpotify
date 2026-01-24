# frozen_string_literal: true
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { "A sample role" }

    trait :admin do
      name { "administrator" }
      description { "Full system access" }
    end

    trait :with_permissions do
      after(:create) do |role|
        role.permissions = create_list(:permission, 3)
      end
    end
  end
end

# == Schema Information
#
# Table name: roles
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#
