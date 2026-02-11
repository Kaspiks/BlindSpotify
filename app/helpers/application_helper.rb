module ApplicationHelper
  include IconHelper
  include FormHelper

  def sortable(column, label:, sort_param: :sort, direction_param: :direction)
    options = params.to_unsafe_h.except(:controller, :action)
    is_column_sorted = options[sort_param] == column.to_s
    direction = is_column_sorted && options[direction_param] == 'asc' ? 'desc' : 'asc'
    reset_sort = is_column_sorted && options[direction_param] == 'desc'

    url_params = options.merge(
      sort_param => reset_sort ? nil : column,
      direction_param => reset_sort ? nil : direction
    )

    link_to(url_params, class: 'table__sortable-link') do
      concat tag.span(label)

      if is_column_sorted
        sort_icon_name = direction == 'asc' ? 'chevron-up' : 'chevron-down'
        sort_icon = icon(sort_icon_name, types: %w[text-left lg bold])

        concat tag.span(sort_icon)
      end
    end
  end

  def message_list(errors, default_message: nil)
    return default_message if errors.blank?

    safe_join(errors.map { |e| tag.div(e.respond_to?(:message) ? e.message : e.to_s) })
  end
end
