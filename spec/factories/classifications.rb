# frozen_string_literal: true

FactoryBot.define do
  factory :classification do
    sequence(:name) { |n| "Classification #{n}" }
    sequence(:code) { |n| "classification_#{n}" }
    description { "A sample classification" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_values do
      after(:create) do |classification|
        create_list(:classification_value, 3, classification: classification)
      end
    end
  end
end
