# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :amazon

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  config.session_store :cookie_store, key: "_early_career_framework_session", secure: true, expire_after: 2.weeks

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :delayed_job
  # config.active_job.queue_name_prefix = "early_career_framework_production"
  config.domain = ENV["DOMAIN"]

  config.support_email = "continuing-professional-development@digital.education.gov.uk"

  config.gias_api_schema = ENV["GIAS_API_SCHEMA"]
  config.gias_extract_id = ENV["GIAS_EXTRACT_ID"]
  config.gias_api_user = ENV["GIAS_API_USER"]
  config.gias_api_password = Rails.application.credentials.GIAS_API_PASSWORD

  config.dqt_client_api_key = Rails.application.credentials.DQT_CLIENT_API_KEY
  config.dqt_client_host = Rails.application.credentials.DQT_CLIENT_HOST
  config.dqt_client_params = Rails.application.credentials.DQT_CLIENT_PARAMS

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :notify
  config.action_mailer.notify_settings = {
    api_key: Rails.application.credentials.GOVUK_NOTIFY_API_KEY,
  }
  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  # Logging
  config.log_level = :info
  config.log_tags = [:request_id] # Prepend all log lines with the following tags.
  logger = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.active_record.logger = nil # Don't log SQL in production

  # Use Lograge for cleaner logging
  config.lograge.enabled = true
  config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.ignore_actions = ["ApplicationController#check"]
  config.lograge.logger = ActiveSupport::Logger.new($stdout)

  # Include params in logs: https://github.com/roidrage/lograge#what-it-doesnt-do
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      params: event.payload[:params].except(*exceptions),
      exception: event.payload[:exception], # ["ExceptionClass", "the message"]
      current_user_class: event.payload[:current_user_class],
      current_user_id: event.payload[:current_user_id],
    }
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  config.cip_resource_bucket = "https://paas-s3-broker-prod-lon-ac28a7a5-2bc2-4d3b-8d16-a88eaef65526.s3.amazonaws.com"
end
