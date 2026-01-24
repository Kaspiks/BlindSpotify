# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:code) { |n| "permission.#{n}" }
    description { "A sample permission" }
  end
end
