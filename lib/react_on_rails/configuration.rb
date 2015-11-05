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
      generator_function: false,
      trace: Rails.env.development?,
      development_mode: Rails.env.development?,
      server_renderer_pool_size: 1,
      server_renderer_timeout: 20)
  end

  class Configuration
    attr_accessor :server_bundle_js_file, :prerender, :replay_console,
                  :generator_function, :trace, :development_mode,
                  :logging_on_server, :server_renderer_pool_size,
                  :server_renderer_timeout

    def initialize(server_bundle_js_file: nil, prerender: nil, replay_console: nil,
                   generator_function: nil, trace: nil, development_mode: nil,
                   logging_on_server: nil, server_renderer_pool_size: nil,
                   server_renderer_timeout: nil)
      if File.exist?(server_bundle_js_file)
        self.server_bundle_js_file = server_bundle_js_file
      else
        self.server_bundle_js_file = nil
      end

      self.prerender = prerender
      self.replay_console = replay_console
      self.logging_on_server = logging_on_server
      self.generator_function = generator_function
      if development_mode.nil?
        self.development_mode = Rails.env.development?
      else
        self.development_mode = development_mode
      end
      self.trace = trace.nil? ? Rails.env.development? : trace

      # Server rendering:
      self.server_renderer_pool_size = self.development_mode ? 1 : server_renderer_pool_size
      self.server_renderer_timeout = server_renderer_timeout # seconds
    end
  end
end
