# frozen_string_literal: true

class NavigationPresenter < ApplicationPresenter
  QuickAction = Struct.new(:title, :icon, :url, :color, :description, keyword_init: true) do
    def icon_color_class
      case color
      when "emerald" then "text-emerald-400"
      when "blue" then "text-blue-400"
      when "amber" then "text-amber-400"
      when "cyan" then "text-cyan-400"
      when "purple" then "text-purple-400"
      when "rose" then "text-rose-400"
      when "orange" then "text-orange-400"
      when "yellow" then "text-yellow-400"
      when "green" then "text-green-400"
      when "red" then "text-red-400"
      else "text-slate-400"
      end
    end

    def bg_color_class
      case color
      when "emerald" then "bg-emerald-500/20"
      when "blue" then "bg-blue-500/20"
      when "amber" then "bg-amber-500/20"
      when "cyan" then "bg-cyan-500/20"
      when "purple" then "bg-purple-500/20"
      when "rose" then "bg-rose-500/20"
      when "orange" then "bg-orange-500/20"
      when "yellow" then "bg-yellow-500/20"
      when "green" then "bg-green-500/20"
      when "red" then "bg-red-500/20"
      else "bg-slate-500/20"
      end
    end
  end

  NavigationSection = Struct.new(:title, :items, keyword_init: true)

  NavigationItem = Struct.new(:title, :icon, :url, :active, keyword_init: true) do
    def active?
      active
    end
  end

  attr_reader :view_context, :controller_path, :current_user

  def initialize(view_context:, controller_path:, user: nil)
    super()
    @view_context = view_context
    @controller_path = controller_path
    @current_user = user
  end

  def navigation_sections
    # Override in subclass to provide navigation sections
    []
  end

  def quick_actions
    # Override in subclass to provide quick actions
    []
  end

  def admin_quick_actions
    # Override in subclass to provide admin quick actions
    []
  end

  protected

  def build_action(title:, icon:, url:, color:, description: nil)
    QuickAction.new(
      title: title,
      icon: icon,
      url: url,
      color: color,
      description: description
    )
  end

  def build_section(title: nil, items:)
    NavigationSection.new(title: title, items: items)
  end

  def build_item(title:, icon:, url:, active: false)
    NavigationItem.new(
      title: title,
      icon: icon,
      url: url,
      active: active
    )
  end

  def active_for?(path_prefix)
    controller_path.start_with?(path_prefix)
  end
end
