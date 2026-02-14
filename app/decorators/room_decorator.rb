# frozen_string_literal: true

class RoomDecorator < ApplicationDecorator
  def display_code
    object.code
  end

  def share_path
    url_helpers.room_join_path(object.code)
  end

  def host_display_name
    return t_context(".anonymous_host") if object.host.blank?
    object.host.name.presence || object.host.email.presence || t_context(".anonymous_host")
  end

  def current_track_display
    return t_context(".no_track") if object.current_track.blank?
    return "???" unless object.revealed?
    "#{object.current_track.artist_name} – #{object.current_track.title}"
  end

  def status_badge
    object.status == "active" ? t_context(".status_active") : t_context(".status_closed")
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
