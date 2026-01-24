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

# == Schema Information
#
# Table name: settings
#
#  id          :bigint           not null, primary key
#  description :text
#  group       :string           default("general")
#  key         :string           not null
#  value       :text
#  value_type  :string           default("string"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_settings_on_group  (group)
#  index_settings_on_key    (key) UNIQUE
#
