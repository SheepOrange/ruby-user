require_relative "boot"
require 'sprockets/railtie'
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BangbangApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.active_record.default_timezone = :local
    config.time_zone = "Sydney"
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # config.eager_load_paths += Dir[Rails.root.join('app', 'api', '*')]
    config.eager_load_paths << Rails.root.join('lib')
    config.active_job.queue_adapter = :sidekiq

    config.session_store :redis_store, {
      servers: [
        { host: ENV['REDIS_HOST'], port: 6379, db: 0 },
      ],
      key: 'bangbang-session'
    }
  end
end
