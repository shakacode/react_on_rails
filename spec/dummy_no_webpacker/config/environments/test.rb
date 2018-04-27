# frozen_string_literal: true

require_relative "../../../react_on_rails/support/rails32_helper"

if using_rails32?
  Dummy::Application.configure do
    config.active_support.deprecation = :stderr
  end
else
  Rails.application.configure do
    config.cache_classes = true
    config.eager_load = false
    config.public_file_server.enabled = true
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=3600"
    }
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection = false
    config.action_mailer.perform_caching = false
    config.action_mailer.delivery_method = :test
    config.active_support.test_order = :random
    config.active_support.deprecation = :stderr
  end
end
