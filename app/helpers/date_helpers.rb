# frozen_string_literal: true

module DateHelpers
  module_function

  def safe_parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)
    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def format_date(date, format: :default)
    return nil if date.blank?

    case format
    when :short
      date.strftime("%b %d")
    when :long
      date.strftime("%B %d, %Y")
    when :iso
      date.iso8601
    else
      date.strftime("%Y-%m-%d")
    end
  end

  def valid_date_range?(start_date, end_date)
    return true if start_date.blank? || end_date.blank?

    start_date <= end_date
  end
end
