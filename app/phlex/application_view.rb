# frozen_string_literal: true

class ApplicationView < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::TurboStreamFrom
end
