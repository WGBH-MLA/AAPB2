require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Xyz
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('lib', 'middleware')
    config.middleware.use('RedirectMiddleware')
    config.middleware.insert_before(0, 'Rack::Cors') do
      allow do
        origins '*'
        resource '/api.*', headers: :any, methods: [:get, :options]
      end
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :options]
      end
    end

    config.exceptions_app = routes
    config.cache_store = :memory_store

    # if Rails.env.development?
    #   reload_gems = %w(cmless) # names of gems which should autoreload
    #   config.autoload_paths += Gem.loaded_specs.values.inject([]){ |a,gem| a += gem.load_paths if reload_gems.include? gem.name; a }
    #   require 'active_support/dependencies'
    #   ActiveSupport::Dependencies.explicitly_unloadable_constants += reload_gems.map { |gem| gem.classify }
    # end
  end
end
