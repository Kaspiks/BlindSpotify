# frozen_string_literal: true

module FormFieldHelpers
  extend ActiveSupport::Concern

  included do
    define_method :cached_association_values do
      @cached_association_values ||= {}
    end
  end

  class_methods do
    def delegated_fields(*field_names)
      field_names.each do |field_name|
        define_method("#{field_name}=") do |new_value|
          instance_variable_set("@#{field_name}", new_value)
          object.public_send("#{field_name}=", new_value)
        end

        define_method(field_name) do
          if errors.key?(field_name.to_sym)
            instance_variable_get("@#{field_name}")
          else
            object.public_send(field_name)
          end
        end
      end
    end

    def decimal_field(field_name)
      attr_writer(field_name)

      define_method(field_name) do
        return instance_variable_get("@#{field_name}") if errors.key?(field_name.to_sym)

        field_value = instance_variable_get("@#{field_name}")

        return if field_value.nil?
        return BigDecimal(field_value) if field_value.is_a?(String)

        field_value.to_d if field_value.respond_to?(:to_d)
      rescue ArgumentError, TypeError
        nil
      end
    end

    def string_field(field_name)
      attr_accessor(field_name)
    end

    def date_field(field_name)
      attr_writer(field_name)

      define_method(field_name) do
        return instance_variable_get("@#{field_name}") if errors.key?(field_name.to_sym)

        field_value = instance_variable_get("@#{field_name}")
        DateHelpers.safe_parse_date(field_value)
      end
    end

    def array_field(field_name, delimiter: AppConfig.choices_delimiter)
      attr_reader(field_name)

      define_method("#{field_name}=") do |new_value|
        new_value = new_value.compact_blank.join(delimiter) if new_value.is_a?(Array)
        instance_variable_set("@#{field_name}", new_value)
      end

      define_method("#{field_name}_array") do
        field_value = instance_variable_get("@#{field_name}")

        return field_value.compact_blank if field_value.is_a?(Array)

        field_value.to_s.split(AppConfig.choices_delimiter).compact_blank
      end
    end

    def boolean_field(field_name)
      attr_writer(field_name)

      define_method(field_name) do
        field_value = instance_variable_get("@#{field_name}")
        mapping = { nil => nil, "1" => true, 1 => true, true => true, "true" => true }
        mapping.fetch(field_value, false)
      end
    end

    def collection_field(field_name, collection:)
      define_collection_field(field_name, collection) do |collection_values, field_value|
        (collection_values & [field_value]).first
      end
    end

    def multiple_collection_field(field_name, collection:)
      define_collection_field(field_name, collection) do |collection_values, field_value|
        collection_values & (field_value || [])
      end
    end

    def association_field(field_name, collection:, mode: :preload)
      define_collection_field(field_name, collection) do |collection_values, field_value|
        cached_association_values[collection] ||= {}

        next if field_value.blank?

        cached_association_values[collection][field_value.to_i] ||=
          case mode
          when :preload
            (collection_values.map(&:id) & [field_value.to_i]).first
          when :find_by_id
            collection_values.where(id: field_value.to_i).pick(:id)
          end
      end
    end

    def association_fields(
      field_scope_map,
      mode: :preload,
      cache_collection: true,
      active_if_supported: true,
      decorators: {},
      modes: {}
    )
      field_scope_map.each do |association_name, association_scope|
        association_mode = modes[association_name] || mode
        is_multiple = association_name.to_s[/ids$/]
        collection_method_name =
          :"#{association_name.to_s.sub(/_(id|ids)$/, '').pluralize}_collection"
        scope_method_name =
          :"#{association_name.to_s.sub(/_(id|ids)$/, '').pluralize}_scope"

        define_method(scope_method_name) do
          scope = association_scope
          scope = instance_exec(&scope) if scope.is_a?(Proc)
          scope = scope.active if active_if_supported && scope.respond_to?(:active)
          scope
        end

        define_method(collection_method_name) do
          instance_val = instance_variable_get("@#{association_name}")
          cache_var_name = ["@#{collection_method_name}", instance_val].join("_")
          is_cached = cache_collection && instance_variable_defined?(cache_var_name)
          is_cached = false if association_scope.is_a?(Proc)

          return instance_variable_get(cache_var_name) if is_cached

          scope = public_send(scope_method_name)

          value =
            case association_mode
            when :preload
              scope.all
            when :find_by_id
              scope.where(id: instance_val)
            end

          instance_variable_set(cache_var_name, value)
          value
        end

        define_method("#{collection_method_name}_for_select") do
          CollectionPresenter.new(public_send(collection_method_name)).items_for_select
        end

        definition_method = :association_field unless is_multiple
        definition_method ||= :multiple_association_field

        has_many_decorated(
          collection_method_name,
          **{
            expose: true,
            cache_mode: (cache_collection ? :static : :dynamic),
            decorator_class_name: decorators[association_name]
          }.compact
        )

        public_send(
          definition_method,
          association_name,
          collection: collection_method_name,
          mode: association_mode
        )
      end
    end

    def multiple_association_field(field_name, collection:, mode: :preload)
      define_collection_field(field_name, collection) do |collection_values, field_value|
        field_values = (field_value.presence || []).compact_blank.map(&:to_i)

        cached_association_values[collection] ||= {}

        field_values_ids = field_values.compact_blank.map(&:to_i)

        case mode
        when :preload
          cached_association_values[collection][:all] ||=
            collection_values.index_by(&:id).transform_values(&:id)

          cached_association_values[collection][:all].values_at(*field_values_ids)
        when :find_by_id
          missing_keys = field_values_ids - cached_association_values[collection].keys

          cached_association_values[collection].merge!(
            collection_values
              .where(id: missing_keys)
              .pluck(:id, :id)
              .to_h
              .reverse_merge!(missing_keys.product([nil]).to_h)
          )

          cached_association_values[collection].values_at(*field_values_ids).compact
        end
      end
    end

    private

    def define_collection_field(field_name, collection, &block)
      is_ivar = collection.to_s[0] == "@"

      attr_writer(field_name)

      define_method(field_name) do
        collection_values = is_ivar ? instance_variable_get(collection) : send(collection)
        field_value = instance_variable_get("@#{field_name}")
        instance_exec(collection_values, field_value, &block)
      end
    end
  end
end
