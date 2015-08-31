module ReactOnRails
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new(
      bundle_js_file: "app/assets/javascripts/generated/server.js",
      prerender: true
    )
  end

  class Configuration
    attr_accessor :bundle_js_file, :prerender

    def initialize(bundle_js_file:, prerender:)
      self.bundle_js_file = bundle_js_file
      self.prerender = prerender
    end
  end
end
