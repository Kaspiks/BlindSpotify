# frozen_string_literal: true

class ApplicationModelForm < ApplicationForm
  attr_reader :object, :original_object

  # Necessary for correct form_for behaviour
  delegate :id, :persisted?, to: :object

  class << self
    attr_accessor :object_class_name

    def reflect_on_association(association, *)
      possible_method = "reflect_on_#{association}"

      return public_send(possible_method) if respond_to?(possible_method)

      object_class.reflect_on_association(association, *)
    end

    def validators_on(*)
      super + object_class.validators_on(*)
    end

    def object_class
      return @object_class if defined?(@object_class)

      unless object_class_name
        suggested_class_name = name.split("::")[-2]&.singularize || "<model name>"

        raise "object_class_name must be defined for classes inheriting ApplicationModelForm\n" \
              "Did you forget?  self.object_class_name = '#{suggested_class_name}'"
      end

      @object_class = object_class_name.constantize
    end
  end

  def initialize(object)
    super()
    @original_object = object.dup
    @object = object
  end

  def update(attributes)
    object.assign_attributes(attributes)
    save
  end
  alias create update

  def form_and_object_valid?(context = nil)
    object.valid?(context)
    valid?(context)

    if object.errors.blank? && errors.blank?
      true
    else
      errors.merge!(object.errors)
      cleanup_errors_duplicates!

      false
    end
  end

  private

  def cleanup_errors_duplicates!
    key_transformations = {}

    normalize_key = proc do |key|
      key = key.to_s
      key_base = nil

      case key
      when /_ids$/
        key_base = key.sub(/_ids$/, "").pluralize

        key_transformations[key_base] = key_base
      when /_id$/
        key_base = key.sub(/_id$/, "")

        key_transformations[key_base] = key_base
      else
        key_base = key
      end

      key_transformations[key_base] ||= key_base
    end

    key_groups = errors.attribute_names.group_by(&normalize_key)

    key_groups.each do |new_key, subgroups|
      key_errors = subgroups.flat_map(&errors.method(:where)).uniq(&:details)

      subgroups.each(&errors.method(:delete))

      key_errors.each { |error| errors.import(error, attribute: new_key.to_sym) }
    end
  end

  def object_class
    self.class.object_class
  end

  def t_context(key, *)
    raise "translation key must be relative\nDid you mean?  .#{key}" unless key[0] == "."

    i18n_scope = self.class.to_s.sub(/Form\z/, "").split("::").compact_blank.join(".").downcase

    I18n.t("forms.#{i18n_scope}#{key}", *)
  end

  def save(raise_error: false)
    if form_and_object_valid?
      result = raise_error ? object.save! : object.save
      # If save failed, capture the object's errors
      unless result
        errors.merge!(object.errors)
      end
      result
    else
      raise ActiveRecord::RecordInvalid, object if raise_error

      false
    end
  end

  def save!
    save(raise_error: true)
  end

  def with_safe_transaction(&)
    ActiveRecord::Base.transaction(&)
  rescue ActiveRecord::RecordInvalid
    false
  end

  def validate_and_handle_result
    return false unless form_and_object_valid?

    result = yield

    result.errors.each { |error| errors.add(:base, error) } unless result.success?

    result.success?
  end

  def assign_attributes_and_call(service_class, attributes)
    service_class.build(object) do |service|
      object.assign_attributes(attributes)

      validate_and_handle_result do
        service.call
      end
    end
  end
end
