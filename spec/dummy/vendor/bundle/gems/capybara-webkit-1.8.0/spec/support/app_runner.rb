# Boots a single Capybara::Server for a Rack application that delegates to another, singleton Rack
# application that can be configured for each spec.

require 'sinatra/base'

module AppRunner
  class << self
    attr_accessor :app, :app_host, :configuration
  end

  def self.boot
    app_container = lambda { |env| AppRunner.app.call(env) }
    server = Capybara::Server.new(app_container)
    server.boot
    self.app_host = "http://127.0.0.1:#{server.port}"
  end

  def self.reset
    self.app = lambda do |env|
      [200, { 'Content-Type' => 'html', 'Content-Length' => 0 }, []]
    end

    self.configuration = Capybara::Webkit::Configuration.new
  end

  def run_application(app)
    AppRunner.app = app
  end

  def configure
    yield AppRunner.configuration
  end

  def driver_for_app(*driver_args, &body)
    app = Class.new(ExampleApp, &body)
    run_application app
    build_driver(*driver_args)
  end

  def driver_for_html(html, *driver_args)
    run_application_for_html html
    build_driver(*driver_args)
  end

  def session_for_app(&body)
    app = Class.new(ExampleApp, &body)
    run_application app
    Capybara::Session.new(:reusable_webkit, AppRunner.app)
  end

  def run_application_for_html(html)
    run_application lambda { |env|
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => html.size.to_s }, [html]]
    }
  end

  private

  def build_driver(overrides = {})
    options = AppRunner.configuration.
      to_hash.
      merge(browser: $webkit_browser).
      merge(overrides)
    Capybara::Webkit::Driver.new(AppRunner.app, options)
  end

  def self.included(example_group)
    example_group.class_eval do
      before { AppRunner.reset }
      after { $webkit_browser.reset! }
    end
  end
end

class ExampleApp < Sinatra::Base
  # Sinatra fixes invalid responses that would break QWebPage, so this middleware breaks them again
  # for testing purposes.
  class ResponseInvalidator
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)
      if response.to_a[1]['X-Response-Invalid']
        [404, {}, []]
      else
        response
      end
    end
  end

  use ResponseInvalidator

  def invalid_response
    [200, { 'X-Response-Invalid' => 'TRUE' }, []]
  end
end

AppRunner.boot
