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
