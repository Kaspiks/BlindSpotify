# frozen_string_literal: true

# Custom SimpleForm input: `as: :tom_select`
#
# Renders a <select> enhanced by Tom Select via the `tom-select` Stimulus controller.
# Pair with the :vertical_tom_select wrapper (defined in simple_form.rb).
#
# Usage:
#   = f.input :playlist_id, as: :tom_select,
#       collection: @playlists, label_method: :name, value_method: :id,
#       include_blank: "Choose…"
#
class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options = nil)
    html_options = merge_wrapper_options(input_html_options, wrapper_options)

    html_options[:data] ||= {}
    html_options[:data][:controller] = append_stimulus_controller(html_options, "tom-select")
    html_options[:data][:tom_select_target] = "field"

    @builder.collection_select(
      attribute_name,
      collection,
      value_method,
      label_method,
      input_options,
      html_options
    )
  end

  def input_options
    super.reverse_merge(include_blank: !multiple?)
  end

  private

  def value_method
    input_options.delete(:value_method) || :id
  end

  def label_method
    input_options.delete(:label_method) || :to_s
  end

  def append_stimulus_controller(html_options, controller)
    existing = html_options.dig(:data, :controller).to_s
    controllers = existing.split.reject(&:blank?)
    controllers << controller unless controllers.include?(controller)
    controllers.join(" ")
  end
end
