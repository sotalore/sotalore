source 'https://rubygems.org'

ruby "3.2.1"

gem 'rails', '~> 7.0.2'
gem 'propshaft'
gem 'pg'
gem 'puma', '~> 5.0'

gem 'jsbundling-rails'
gem "cssbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem "image_processing", ">= 1.2"
gem "aws-sdk-s3", require: false

gem 'lograge'

gem 'bootsnap'

gem 'haml-rails'
gem 'kaminari'
gem 'local_time'
gem 'active_link_to'
gem 'redcarpet'

gem 'devise'
gem 'pg_search'
gem 'pundit'
gem 'faraday'

gem 'scout_apm'
gem "honeybadger", "~> 5.0"

gem 'activeadmin'

gem 'icalendar'

group :test do
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'rspec-rails', ">= 4.0.0.beta"
  gem 'factory_bot_rails'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'hotwire-livereload'
  gem 'listen'
  gem 'guard'
  gem 'guard-rspec'
  gem 'libnotify'
end
