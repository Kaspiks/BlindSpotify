# frozen_string_literal: true

module Playlists
  class Form < ApplicationModelForm
    self.object_class_name = "Playlist"

    delegate :genre_id, :genre_id=, :name, :name=, :description, :description=, to: :object

    attr_accessor :deezer_url

    validates :genre_id, presence: true

    def create(attributes)
      assign_deezer_attributes(attributes)
      object.assign_attributes(attributes.except(:deezer_url))

      # Set a temporary name if we have a Deezer ID (will be updated during import)
      object.name = t_context(".importing_name") if object.name.blank? && object.deezer_id.present?

      if save
        schedule_import if object.deezer_id.present?
        true
      else
        false
      end
    end

    def update(attributes)
      object.assign_attributes(attributes.except(:deezer_url))
      save
    end

    def available_genres
      ClassificationValue.for_classification("genre").ordered
    end

    def should_import?
      object.deezer_id.present? && object.persisted?
    end

    private

    def assign_deezer_attributes(attributes)
      self.deezer_url = attributes[:deezer_url]

      if deezer_url.present?
        object.deezer_url = deezer_url
        object.deezer_id = Playlist.extract_deezer_id(deezer_url)
      end
    end

    def schedule_import
      PlaylistImportJob.perform_later(object.id)
    end
  end
end
