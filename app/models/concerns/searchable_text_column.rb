# frozen_string_literal: true

module SearchableTextColumn
  extend ActiveSupport::Concern

  class_methods do
    def searchable_text_column(column_name)
      define_singleton_method("#{column_name}_matches") do |value|
        sanitized_value = sanitize_sql_like(value)

        where(arel_table[:"#{column_name}"].matches("%#{sanitized_value}%"))
      end
    end
  end
end
