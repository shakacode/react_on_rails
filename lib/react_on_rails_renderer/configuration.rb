module ReactOnRailsRenderer
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||=  Configuration.new(
      renderer_protocol: "http",
      renderer_host: "localhost",
    )
  end

  class Configuration
    attr_accessor :renderer_protocol, :renderer_host, :renderer_port

    def initialize(renderer_protocol: nil, renderer_host: nil, renderer_port: nil)
      self.renderer_protocol = renderer_protocol
      self.renderer_host = renderer_host
      self.renderer_port = renderer_port
    end
  end
end
