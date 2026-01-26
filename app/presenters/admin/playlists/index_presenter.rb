# frozen_string_literal: true

module Admin
  module Playlists
    class IndexPresenter < ::IndexPresenter
      def initialize(playlists:)
        super(collection: playlists, decorator: false)
      end

      def page_title
        t_context(".page_title")
      end

      def playlists
        decorated_collection
      end
    end
  end
end
