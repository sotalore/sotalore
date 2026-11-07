require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SotaLore
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

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

    # Requests reach the app through Cloudflare, then Heroku's router. In
    # production the cloudflare-rails gem trusts Cloudflare's ranges, so
    # request.remote_ip is the last X-Forwarded-For entry before Cloudflare's:
    # the visitor's address, which a client can't fake.
    #
    # Neither Cloudflare nor Heroku sets the Forwarded header, they pass along
    # whatever the client sent. Rack reads it ahead of X-Forwarded-For by
    # default, which would let a client choose its own address, so read only
    # X-Forwarded-For.
    Rack::Request.forwarded_priority = [ :x_forwarded ]

    # Scanners send fake Client-IP and Forwarded headers, and the spoofing check
    # turned each of those requests into an IpSpoofAttackError. With Forwarded
    # ignored, remote_ip doesn't use the values a client can fake, so the check
    # adds nothing.
    config.action_dispatch.ip_spoofing_check = false

    if Rails.env.development?
      config.hosts << 'gaffer.local'
    end
  end
end
