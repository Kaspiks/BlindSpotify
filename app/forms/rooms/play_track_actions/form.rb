# frozen_string_literal: true

module Rooms
  module PlayTrackActions
    class Form < ApplicationModelForm
      self.object_class_name = "Room"

      attr_accessor :track_id, :track_token, :deck_id, :position

      def self.model_name
        ActiveModel::Name.new(self, nil, "RoomsPlayTrackActionsForm")
      end

      validates :track, presence: true

      def create(attributes = {})
        assign_form_attributes(attributes)
        return false unless form_and_object_valid?
        Rooms::PlayTrackService.call(room: object, track: track)
        true
      end

      def track
        @track ||= resolve_track
      end

      def room
        object
      end

      private

      def assign_form_attributes(attrs)
        attrs = attrs.to_h.with_indifferent_access
        self.track_id = attrs[:track_id]
        self.track_token = attrs[:track_token]
        self.deck_id = attrs[:deck_id]
        self.position = attrs[:position]
      end

      def resolve_track
        if track_id.present?
          Track.find_by(id: track_id)
        elsif track_token.present?
          Track.find_by(token: track_token)
        elsif deck_id.present? && position.present?
          deck = ArucoDeck.find_by(id: deck_id)
          deck&.slot_at(position.to_i)
        end
      end
    end
  end
end
