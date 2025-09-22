source 'https://rubygems.org'

ruby "3.4.6"

gem "ostruct" # silence deprecation warning

gem 'rails', '~> 8.0.0'
gem 'propshaft'
gem 'pg'
gem 'puma', '~> 6.0'

gem 'jsbundling-rails'
gem "cssbundling-rails"

gem 'turbo-rails'
gem 'stimulus-rails'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.0', group: :development
# Use ActiveModel has_secure_password
gem 'bcrypt'

gem "image_processing", ">= 1.2"
gem "aws-sdk-s3", require: false

gem 'lograge'
gem 'logtail-rails'

gem 'bootsnap'

gem 'haml-rails'
gem "phlex-rails"
gem "phlex"

gem 'kaminari'
gem 'local_time'
gem 'active_link_to'
gem 'redcarpet'

gem 'omniauth-discord'
gem 'omniauth-rails_csrf_protection'
gem 'pg_search'
gem 'pundit'
gem 'faraday'

gem "honeybadger", "~> 5.0"

gem 'icalendar'
gem 'csv'


group :production do
  gem 'cloudflare-rails'
end

group :test do
  gem "capybara"
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'brakeman', require: false
end

group :development do
  gem 'guard-rspec', require: false
  gem 'hotwire-spark'
  gem 'listen'
  gem 'guard'
  gem 'libnotify'
end
