# frozen_string_literal: true

module Rooms
  class Form < ApplicationModelForm
    self.object_class_name = "Room"

    attr_accessor :host_id, :playlist_id

    def self.model_name
      ActiveModel::Name.new(self, nil, "RoomsForm")
    end

    def initialize(object, host: nil)
      super(object)
      @host = host
    end

    def create(attributes = {})
      self.host_id = attributes[:host_id] || @host&.id
      self.playlist_id = attributes[:playlist_id]
      object.host_id = host_id
      object.playlist_id = playlist_id if playlist_id.present?
      return false unless form_and_object_valid?
      save
    end
  end
end
