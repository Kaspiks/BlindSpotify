# frozen_string_literal: true

module Games
  class Form < ApplicationModelForm
    self.object_class_name = "Game"

    attr_accessor :playlist_id

    validates :playlist_id, presence: true
    validate :playlist_has_tracks

    def create(attributes)
      self.playlist_id = attributes[:playlist_id]

      # Find and assign playlist before validation
      playlist = Playlist.find_by(id: playlist_id)
      object.playlist = playlist if playlist

      return false unless form_and_object_valid?

      save
    end

    def available_playlists_by_genre(user)
      Playlist.includes(:genre, :tracks)
              .where(user: user)
              .where.not(import_status: "pending")
              .select { |p| p.tracks.any? }
              .group_by(&:genre)
    end

    private

    def playlist_has_tracks
      return if playlist_id.blank?

      playlist = Playlist.find_by(id: playlist_id)
      return add_playlist_error unless playlist

      if playlist.tracks.empty?
        errors.add(:playlist_id, :no_tracks)
      end
    end

    def add_playlist_error
      errors.add(:playlist_id, :not_found)
      false
    end
  end
end
