# frozen_string_literal: true

FactoryBot.define do
  factory :setting do
    sequence(:key) { |n| "setting.key_#{n}" }
    value { "sample value" }
    value_type { "string" }
    group { "general" }
    description { "A sample setting" }

    trait :boolean do
      value { "true" }
      value_type { "boolean" }
    end

    trait :integer do
      value { "42" }
      value_type { "integer" }
    end

    trait :text do
      value { "Long text content here" }
      value_type { "text" }
    end
  end
end
