# frozen_string_literal: true

module Admin
  module ArucoDecks
    class IndexPresenter < ::IndexPresenter
      def initialize(decks:)
        super(collection: decks, decorator: false)
      end

      def page_title
        t_context(".page_title")
      end

      def decks
        decorated_collection
      end
    end
  end
end
