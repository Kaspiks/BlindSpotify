source "https://rubygems.org"

gem "rails", "~> 8.0.0", ">= 8.0.0.1"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

gem "slim-rails"

gem "devise"
gem "omniauth"
gem "omniauth-spotify"
gem "omniauth-rails_csrf_protection"

gem "pundit"

gem "redis", "~> 5.0"
gem "redis-actionpack", "~> 5.4"

gem "simple_form"

# gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

gem "kamal", require: false

gem "thruster", require: false

# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw mswin x64_mingw ], require: "debug/prelude"

  gem "brakeman", require: false

  gem "rubocop-rails-omakase", require: false

  gem "pry"
  gem "pry-byebug"
end

gem "validates_lengths_from_database", "~> 0.8.0"

group :development do
  gem "web-console"

  # Annotate models with schema info [https://github.com/drwl/annotaterb]
  gem "annotaterb"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end

gem "json_schemer"
