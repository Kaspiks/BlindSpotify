# frozen_string_literal: true

module Admin
  class NavigationPresenter < ApplicationPresenter
    NavigationSection = Struct.new(:title, :items)
    NavigationItem = Struct.new(:title, :icon, :url, :active?)

    def initialize(view_context:, controller_path:, user:)
      super()
      @view_context = view_context
      @controller_path = controller_path
      @controller_name = controller_path.split("/").last
      @user = user
    end

    def navigation_sections
      sections.map do |section, section_items|
        section_name = section ? t_context(".sections.#{section}.title") : nil
        NavigationSection.new(section_name, section_items)
      end
    end

    def quick_actions
      [
        build_action(title: t_context(".quick_actions.manage_users"), icon: "users", url: @view_context.admin_users_path, color: "blue", description: t_context(".quick_actions.manage_users_desc")),
        build_action(title: t_context(".quick_actions.manage_roles"), icon: "shield", url: @view_context.admin_roles_path, color: "amber", description: t_context(".quick_actions.manage_roles_desc")),
        build_action(title: t_context(".quick_actions.classifications"), icon: "category", url: @view_context.admin_classification_items_path, color: "purple", description: t_context(".quick_actions.classifications_desc")),
        build_action(title: t_context(".quick_actions.settings"), icon: "settings", url: @view_context.admin_settings_path, color: "cyan", description: t_context(".quick_actions.settings_desc"))
      ]
    end

    private

    def build_action(title:, icon:, url:, color:, description: nil)
      ::NavigationPresenter::QuickAction.new(
        title: title,
        icon: icon,
        url: url,
        color: color,
        description: description
      )
    end

    def sections
      data_for_sections.reduce({}) do |result, (section, items)|
        visible_items = items.compact
        visible_items.present? ? result.merge(section => visible_items) : result
      end
    end

    def data_for_sections
      {
        nil => general_nav_items,
        cards: cards_nav_items,
        configuration: configuration_nav_items
      }
    end

    def general_nav_items
      [
        dashboard_nav_item,
        users_nav_item,
        roles_nav_item
      ]
    end

    def cards_nav_items
      [
        playlists_nav_item,
        aruco_decks_nav_item
      ]
    end

    def configuration_nav_items
      [
        classification_items_nav_item,
        settings_nav_item
      ]
    end

    def dashboard_nav_item
      NavigationItem.new(
        t_context(".items.dashboard"),
        "home",
        @view_context.admin_root_path,
        @controller_name == "dashboard"
      )
    end

    def users_nav_item
      NavigationItem.new(
        t_context(".items.users"),
        "users",
        @view_context.admin_users_path,
        @controller_name == "users"
      )
    end

    def roles_nav_item
      NavigationItem.new(
        t_context(".items.roles"),
        "lock",
        @view_context.admin_roles_path,
        @controller_name == "roles"
      )
    end

    def playlists_nav_item
      NavigationItem.new(
        t_context(".items.playlists"),
        "playlist",
        @view_context.admin_playlists_path,
        @controller_name == "playlists"
      )
    end

    def aruco_decks_nav_item
      NavigationItem.new(
        t_context(".items.aruco_decks"),
        "play-card-star",
        @view_context.admin_aruco_decks_path,
        @controller_name == "aruco_decks"
      )
    end


    def classification_items_nav_item
      return unless Admin::ClassificationItemPolicy.new(@user, nil).index?

      NavigationItem.new(
        t_context(".items.classification_items"),
        "category",
        @view_context.admin_classification_items_path,
        @controller_name == "classification_items"
      )
    end

    def settings_nav_item
      NavigationItem.new(
        t_context(".items.settings"),
        "settings",
        @view_context.admin_settings_path,
        @controller_name == "settings"
      )
    end
  end
end
