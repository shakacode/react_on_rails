module ReactOnRails
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new(
      bundle_js_file: "app/assets/javascripts/generated/server.js",
      prerender: false,
      replay_console: true,
      generator_function: false
    )
  end

  class Configuration
    attr_accessor :bundle_js_file, :prerender, :replay_console, :generator_function

    def initialize(bundle_js_file:, prerender:, replay_console:, generator_function:)
      self.bundle_js_file = bundle_js_file
      self.prerender = prerender
      self.replay_console = replay_console
      self.generator_function = generator_function
    end
  end
end
