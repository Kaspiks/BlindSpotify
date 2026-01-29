# frozen_string_literal: true

module Admin
  module Playlists
    module ReleaseYearsActions
      class Form < ApplicationModelForm
        self.object_class_name = "Playlist"

        attr_accessor :tracks

        def self.model_name
          ActiveModel::Name.new(self, nil, "AdminPlaylistsReleaseYearsActionsForm")
        end

        def initialize(playlist)
          super(playlist)
        end

        def update(attributes)
          assign_form_attributes(attributes)

          result = with_safe_transaction do
            save_release_years
            true
          end

          result.present?
        end

        def playlist
          object
        end

        private

        def assign_form_attributes(attributes)
          attrs = attributes.to_h.with_indifferent_access
          self.tracks = attrs[:tracks] || {}
        end

        def save_release_years
          return if tracks.blank?

          track_ids = playlist.tracks.pluck(:id).map(&:to_s)

          tracks.each do |track_id, attrs|
            next unless track_ids.include?(track_id.to_s)

            year_str = (attrs[:release_year] || attrs["release_year"]).to_s.strip
            next if year_str.blank?

            year_i = year_str.to_i
            unless year_i.between?(1900, Time.current.year)
              errors.add(:base, :invalid_year, year: year_str)
              raise ActiveRecord::Rollback
            end

            track = playlist.tracks.find_by(id: track_id)
            next unless track

            unless track.update(release_year: year_i)
              errors.add(:base, :track_release_year_failed, track_title: track.title, messages: track.errors.full_messages.join(", "))
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end
  end
end
