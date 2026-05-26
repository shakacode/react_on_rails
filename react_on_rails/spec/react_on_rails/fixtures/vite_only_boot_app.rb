# frozen_string_literal: true

# Boots a minimal Rails application that requires react_on_rails without any
# Shakapacker configuration on disk. Used by engine_spec.rb to verify the
# Shakapacker packageManager guard suppression works in a real Rails boot,
# not just in unit tests with stubbed constants.
#
# Invoked by Open3.capture3 as a subprocess; ARGV[0] is the path to the
# react_on_rails lib directory, ARGV[1] is the temp Rails app root.

require "logger"
require "pathname"

lib_path = ARGV.fetch(0)
app_root = Pathname.new(ARGV.fetch(1))
$LOAD_PATH.unshift(lib_path)

require "rails"
require "action_controller/railtie"
require "react_on_rails"

module ViteOnlyBootApp
end

ViteOnlyBootApp.const_set(
  :Application,
  Class.new(Rails::Application) do
    config.root = app_root
    config.eager_load = false
    config.secret_key_base = "test-secret"
    config.logger = Logger.new($stdout)
    config.load_defaults Rails::VERSION::STRING.to_f
  end
)

ViteOnlyBootApp::Application.initialize!
puts "booted"
