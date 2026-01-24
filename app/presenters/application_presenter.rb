# frozen_string_literal: true

class ApplicationPresenter
  include DecoratorHelpers

  def initialize
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def t_context(key, **)
    raise "translation key must be relative\nDid you mean?  .#{key}" unless key.to_s[0] == "."

    i18n_scope = self.class.to_s.sub(/Presenter\z/, "").underscore.tr("/", ".")

    I18n.t("presenters.#{i18n_scope}#{key}", **)
  end
end
