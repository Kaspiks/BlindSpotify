# frozen_string_literal: true

module Admin
  module Settings
    class IndexPresenter < ::ApplicationPresenter
      attr_reader :settings, :settings_by_group

      def initialize(settings:)
        super()
        @settings = settings
        @settings_by_group = settings.group_by(&:group)
      end

      def page_title
        t_context(".page_title")
      end

      def groups
        settings_by_group.keys.sort
      end

      def settings_for_group(group)
        settings_by_group[group] || []
      end
    end
  end
end
