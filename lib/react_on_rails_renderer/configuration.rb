module ReactOnRailsRenderer
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||=  Configuration.new(
      renderer_host: "localhost",
      renderer_port: 3700
    )
  end

  class Configuration
    attr_accessor :renderer_host, :renderer_port

    def initialize(renderer_host: nil, renderer_port: nil)
      self.renderer_host = renderer_host
      self.renderer_port = renderer_port
    end
  end
end
