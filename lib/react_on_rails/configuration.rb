require 'react_on_rails/version'

module ReactOnRails
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new(
      server_bundle_js_file: "app/assets/javascripts/generated/server.js",
      prerender: false,
      replay_console: true,
      logging_on_server: true,
      raise_on_prerender_error: false,
      trace: Rails.env.development?,
      development_mode: Rails.env.development?,
      server_renderer_pool_size: 1,
      server_renderer_timeout: 20)
    # TODO ROB: do the version check
  end

  # TODO ROB
  # parse the client/package.json and ensure that either:
  # 1. version number matches
  # 2. version number is a relative path (for testing)
  # Throw error if not.
  # Allow skipping this check in the configuration in case somebody has a wacky configuration, such
  # as you don't know where their package.json

  def warn_if_module_and_gem_versions_dont_match
    gem_version = ReactOnRails::VERSION
    package_json = Rails.root.join("client", "package.json")
    node_module_version = File.read(package_json).match(/"\n\s*react-on-rails": "(.*)"\s*\n/)[0]
    processed_node_module_version = node_module_version.delete("^")
    return unless gem_version != processed_node_module_version
    puts "**WARNING** ReactOnRails: your version of the ReactOnRails gem (#{gem_version})\n" \
         "is not equal to your installed version of the react-on-rails node module\n" \
         "(#{processed_node_module_version}). Using different versions may result in\n" \
         "compatibility issues."
  end

  class Configuration
    attr_accessor :server_bundle_js_file, :prerender, :replay_console,
                  :trace, :development_mode,
                  :logging_on_server, :server_renderer_pool_size,
                  :server_renderer_timeout, :raise_on_prerender_error

    def initialize(server_bundle_js_file: nil, prerender: nil, replay_console: nil,
                   trace: nil, development_mode: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil, raise_on_prerender_error: nil)
      if File.exist?(server_bundle_js_file)
        self.server_bundle_js_file = server_bundle_js_file
      else
        self.server_bundle_js_file = nil
      end

      self.prerender = prerender
      self.replay_console = replay_console
      self.logging_on_server = logging_on_server
      if development_mode.nil?
        self.development_mode = Rails.env.development?
      else
        self.development_mode = development_mode
      end
      self.trace = trace.nil? ? Rails.env.development? : trace
      self.raise_on_prerender_error = raise_on_prerender_error

      # Server rendering:
      self.server_renderer_pool_size = self.development_mode ? 1 : server_renderer_pool_size
      self.server_renderer_timeout = server_renderer_timeout # seconds
    end
  end
end
