module ReactOnRailsPro
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new(
      renderer_protocol: "http",
      renderer_host: "localhost",
      server_render_method: "",
      password: "",
      use_fallback_renderer_exec_js: true
    )
  end

  class Configuration
    attr_accessor :renderer_protocol, :renderer_host, :renderer_port, :password,
                  :server_render_method, :use_fallback_renderer_exec_js

    def initialize(renderer_protocol: nil, renderer_host: nil, renderer_port: nil, password: nil,
                   server_render_method: nil, use_fallback_renderer_exec_js: nil)
      self.renderer_protocol = renderer_protocol
      self.renderer_host = renderer_host
      self.renderer_port = renderer_port
      self.password = password
      self.server_render_method = server_render_method
      self.use_fallback_renderer_exec_js = use_fallback_renderer_exec_js
    end
  end
end
