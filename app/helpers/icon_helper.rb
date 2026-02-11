# frozen_string_literal: true

module IconHelper
  def render_svg_icons
    icon_path = Rails.root.join("vendor/assets/images/icons.svg")
    return "" unless File.exist?(icon_path)

    cache_key = "asset_helper_svg_icons/v#{File.mtime(icon_path).to_i}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      raw(File.read(icon_path)) # rubocop:disable Rails/OutputSafety
    end
  end

  def icon(name, types: [], width: 24, height: 24, color: nil, **options)
    icon_name = name.to_s.downcase.gsub('_', '-')
    svg_classes = ["icon"] + types.map { |type| "icon--#{type}" }

    custom_classes = options.delete(:class)
    svg_classes += custom_classes.to_s.split if custom_classes.present?

    use_tag = tag.use(nil, href: "##{icon_name}")

    tag.svg(
      use_tag,
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 24 24",
      width: width,
      height: height,
      class: svg_classes.join(" "),
      style: color ? "color: #{color}" : nil,
      **options
    )
  end

  def icon_sm(name, **options)
    icon(name, width: 16, height: 16, types: [:sm], **options)
  end

  def icon_lg(name, **options)
    icon(name, width: 32, height: 32, types: [:lg], **options)
  end
end
