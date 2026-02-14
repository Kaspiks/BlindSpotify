# frozen_string_literal: true

module Rooms
  class ShowPresenter < ::ShowPresenter
    delegate :current_track, :revealed, :code, :host_id, :current_track_id, :active?, to: :object

    attr_reader :current_user

    def initialize(object:, current_user: nil, decorator: RoomDecorator)
      super(object: object, decorator: decorator)
      @current_user = current_user
    end

    def page_title
      t_context(".page_title", code: object.code)
    end

    def share_label
      t_context(".share_label")
    end

    def copied_label
      t_context(".copied_label")
    end

    def copy_code_label
      t_context(".copy_code_label")
    end

    def reveal_label
      t_context(".reveal_label")
    end

    def next_label
      t_context(".next_label")
    end

    def scan_card_label
      t_context(".scan_card_label")
    end

    def mystery_text
      t_context(".mystery_text")
    end

    def mystery_hint
      t_context(".mystery_hint")
    end

    def no_track_message
      t_context(".no_track_message")
    end

    def host?
      object.host?(current_user)
    end

    def back_label
      t_context(".back_label")
    end
  end
end
