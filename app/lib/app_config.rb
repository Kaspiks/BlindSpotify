# frozen_string_literal: true

class AppConfig
  class << self
    attr_writer :choices_delimiter, :default_per_page, :date_format

    def choices_delimiter
      @choices_delimiter ||= ","
    end

    def default_per_page
      @default_per_page ||= 25
    end

    def date_format
      @date_format ||= "%Y-%m-%d"
    end

    def configure
      yield self
    end

    def instance
      self
    end
  end
end
