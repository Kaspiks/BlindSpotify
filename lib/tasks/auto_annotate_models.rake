# frozen_string_literal: true

if Rails.env.development?
  require "annotaterb"

  Rake::Task["db:migrate"].enhance do
    system("bundle exec annotaterb models --position_in_class=bottom")
  end

  Rake::Task["db:rollback"].enhance do
    system("bundle exec annotaterb models --position_in_class=bottom")
  end
end
