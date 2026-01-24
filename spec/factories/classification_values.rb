# frozen_string_literal: true

FactoryBot.define do
  factory :classification_value do
    classification
    sequence(:value) { |n| "Value #{n}" }
    description { "A sample value" }
    sort_order { 0 }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
