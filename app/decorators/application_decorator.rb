# frozen_string_literal: true

class ApplicationDecorator < SimpleDelegator
  include DecoratorHelpers

  alias object __getobj__

  delegate :to_param, :to_key, to: :object

  def initialize(object)
    super(object)
  end

  def to_model
    object
  end

  def t_context(key, *args, **kwargs)
    raise "translation key must be relative\nDid you mean?  .#{key}" unless key[0] == '.'

    i18n_scope = self.class.i18n_scope

    if kwargs[:default].is_a?(Array)
      kwargs[:default] = kwargs[:default].map do |v|
        next v unless v.is_a?(Symbol)
        next v unless v.start_with?('.')

        "decorators.#{i18n_scope}#{v}".to_sym
      end
    end

    I18n.t("decorators.#{i18n_scope}#{key}", *args, **kwargs)
  end

  def self.i18n_scope
    @i18n_scope ||= name.to_s.sub(/Decorator\z/, '').underscore.tr('/', '.')
  end

  def inspect
    "#<#{self.class.name} object: #{object.inspect}>"
  end
end
