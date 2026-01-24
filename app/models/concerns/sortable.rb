# frozen_string_literal: true

module Sortable
  extend ActiveSupport::Concern

  DEFAULT_SORT = :id
  DEFAULT_DIRECTION = :desc

  included do
    class_attribute :filtered_columns
    class_attribute :default_column
    class_attribute :default_direction
  end

  module ClassMethods
    def sorted(sorting_params)
      sorting_params = sorting_params.to_h.symbolize_keys

      direction = sort_direction(sorting_params)
      column = sorting_params[:sort]&.to_sym
      block = filtered_columns[column] || filtered_columns[default_column]

      merge(block.call(direction)).merge(filtered_columns[DEFAULT_SORT].call(direction))
    end

    protected

    def sortable_by(scopes)
      self.default_column = scopes.dig(:defaults, :column) || DEFAULT_SORT
      self.default_direction = scopes.dig(:defaults, :direction) || DEFAULT_DIRECTION

      self.filtered_columns ||= {}
      self.filtered_columns[DEFAULT_SORT] = ->(direction) { order(DEFAULT_SORT => direction) }

      scopes[:columns]&.each do |column|
        self.filtered_columns[column] = ->(direction) { order(column => direction) }
      end

      scopes[:scopes]&.each do |key, value|
        self.filtered_columns[key] = value
      end

      self.filtered_columns
    end

    def sort_direction(sorting_params)
      return default_direction unless directions.include?(sorting_params[:direction]&.to_sym)

      sorting_params[:direction]
    end

    def directions
      [:asc, :desc]
    end
  end
end
