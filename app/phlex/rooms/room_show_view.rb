# frozen_string_literal: true

module Rooms
  class RoomShowView < ApplicationView
    def initialize(room:, show_presenter:)
      @room = room
      @show_presenter = show_presenter
    end

    def view_template
      content_for :title, @show_presenter.page_title
      content_for :head, (helpers.action_cable_meta_tag || "")

      raw helpers.turbo_stream_from("room_#{@room.id}")

      div(class: "max-w-6xl mx-auto px-4 py-8", data: { controller: "room-session", room_session_code_value: @room.code }) do
        div(class: "grid grid-cols-1 lg:grid-cols-[1fr,280px] gap-8") do
          div(class: "min-w-0") do
            if @show_presenter.host?
              render_host_controls
            else
              render_player_waiting
            end
            raw helpers.render(partial: "rooms/room_player", locals: { room: @room })
          end
          div(class: "lg:order-2") do
            raw helpers.render(partial: "rooms/room_players", locals: { room: @room })
          end
        end
      end
    end

    private

    def render_host_controls
      div(class: "flex items-center justify-between mb-6") do
        link_to root_path, class: "flex items-center gap-2 text-slate-400 hover:text-white transition-colors" do
          raw helpers.icon("arrow-left", class: "w-5 h-5")
          span { @show_presenter.back_label }
        end
        div(class: "flex items-center gap-3") do
          span(class: "font-mono text-lg font-bold text-white bg-slate-700 px-4 py-2 rounded-lg") { @show_presenter.decorated_object.display_code }
          raw helpers.content_tag(:button,
            helpers.icon("link", class: "w-4 h-4") + " " + @show_presenter.share_label,
            type: "button",
            class: "px-3 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-slate-300 text-sm inline-flex items-center gap-1",
            data: {
              controller: "clipboard",
              clipboard_text_value: helpers.room_share_full_url(@room),
              clipboard_success_message_value: @show_presenter.copied_label,
              clipboard_label_value: @show_presenter.share_label,
              action: "click->clipboard#copy"
            })
        end
      end
      div(class: "flex flex-wrap gap-3 mb-6") do
        raw helpers.button_to(
          room_reveal_actions_path(@room),
          method: :post,
          class: "inline-flex items-center gap-2 px-4 py-3 bg-slate-700 hover:bg-slate-600 text-white font-medium rounded-xl transition-colors",
          disabled: @room.current_track.blank?
        ) { (helpers.icon("eye", class: "w-5 h-5") + " " + @show_presenter.reveal_label).html_safe }
        raw helpers.button_to(
          room_next_actions_path(@room),
          method: :post,
          class: "inline-flex items-center gap-2 px-4 py-3 bg-purple-600 hover:bg-purple-500 text-white font-medium rounded-xl transition-colors"
        ) { (helpers.icon("arrow-right", class: "w-5 h-5") + " " + @show_presenter.next_label).html_safe }
      end
    end

    def render_player_waiting
      div(class: "mb-4 flex justify-center") do
        span(class: "font-mono text-sm text-slate-500") do
          helpers.t("views.rooms.room_code_label", default: "Room %{code}") % { code: @room.code }
        end
      end
      div(class: "mb-6 flex flex-col items-center justify-center rounded-2xl bg-slate-800 p-12 text-center min-h-[220px]") do
        p(class: "text-3xl md:text-4xl lg:text-5xl font-bold text-white tracking-tight leading-tight") do
          Setting.get("room_start_message", default: "Waiting for host")
        end
      end
    end
  end
end
