module ReactOnRailsPro
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new(
      renderer_url: "http://localhost",
      server_render_method: "VmRenderer",
      password: "",
      use_fallback_renderer_exec_js: true,
      prerender_caching: false,
      http_pool_size: 10,
      http_pool_timeout: 5,
      http_pool_warn_timeout: 0.25
    )
  end

  class Configuration
    attr_accessor :renderer_url, :renderer_port, :password,
                  :server_render_method, :use_fallback_renderer_exec_js, :prerender_caching,
                  :http_pool_size, :http_pool_timeout, :http_pool_warn_timeout

    def initialize(renderer_url: nil, password: nil, server_render_method: nil,
                   use_fallback_renderer_exec_js: nil, prerender_caching: nil,
                   http_pool_size: nil, http_pool_timeout: nil, http_pool_warn_timeout: nil)
      self.renderer_url = renderer_url
      self.password = password
      self.server_render_method = server_render_method
      self.use_fallback_renderer_exec_js = use_fallback_renderer_exec_js
      self.prerender_caching = prerender_caching
      self.http_pool_size = http_pool_size
      self.http_pool_timeout = http_pool_timeout
      self.http_pool_warn_timeout = http_pool_warn_timeout
    end
  end
end
