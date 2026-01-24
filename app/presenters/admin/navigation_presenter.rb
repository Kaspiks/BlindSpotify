# frozen_string_literal: true

module Admin
  class NavigationPresenter < ::NavigationPresenter
    def navigation_sections
      [
        build_section(
          items: [
            build_item(title: "Dashboard", icon: "home", url: view_context.admin_root_path, active: active_for?("admin/dashboard")),
            build_item(title: "Users", icon: "users", url: view_context.admin_users_path, active: active_for?("admin/users")),
            build_item(title: "Roles", icon: "shield", url: view_context.admin_roles_path, active: active_for?("admin/roles"))
          ]
        ),
        build_section(
          title: "Cards",
          items: [
            build_item(title: "Playlists", icon: "playlist", url: view_context.admin_playlists_path, active: active_for?("admin/playlists"))
          ]
        ),
        build_section(
          title: "Configuration",
          items: [
            build_item(title: "Classifications", icon: "category", url: view_context.admin_classification_items_path, active: active_for?("admin/classification")),
            build_item(title: "Settings", icon: "settings", url: view_context.admin_settings_path, active: active_for?("admin/settings"))
          ]
        )
      ]
    end

    def quick_actions
      [
        build_action(
          title: "Manage Users",
          icon: "users",
          url: view_context.admin_users_path,
          color: "blue",
          description: "View and manage user accounts"
        ),
        build_action(
          title: "Manage Roles",
          icon: "shield",
          url: view_context.admin_roles_path,
          color: "amber",
          description: "Configure roles and permissions"
        ),
        build_action(
          title: "Classifications",
          icon: "category",
          url: view_context.admin_classification_items_path,
          color: "purple",
          description: "Manage classification values"
        ),
        build_action(
          title: "Settings",
          icon: "settings",
          url: view_context.admin_settings_path,
          color: "cyan",
          description: "Configure application settings"
        )
      ]
    end
  end
end
