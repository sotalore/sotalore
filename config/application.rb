require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SotaLore
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_support.cache_format_version = 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.time_zone = 'America/Los_Angeles'

    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.belongs_to_required_by_default = false

    config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag }

    if Rails.env.development?
      config.hosts << 'gaffer.local'
    end
  end
end
