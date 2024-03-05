source 'https://rubygems.org'

ruby "3.3.0"

gem 'rails', '~> 7.1.0'
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

gem 'bootsnap'

gem 'haml-rails'
gem 'kaminari'
gem 'local_time'
gem 'active_link_to'
gem 'redcarpet'

gem 'omniauth-discord'
gem 'omniauth-rails_csrf_protection'
gem 'pg_search'
gem 'pundit'
gem 'faraday'

gem 'scout_apm'
gem "honeybadger", "~> 5.0"

gem 'icalendar'

group :test do
  gem "capybara"
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'hotwire-livereload'
  gem 'listen'
  gem 'guard'
  gem 'libnotify'
end
