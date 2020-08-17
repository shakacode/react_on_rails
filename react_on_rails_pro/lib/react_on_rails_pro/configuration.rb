# frozen_string_literal: true

module ReactOnRailsPro
  def self.configure
    yield(configuration)
    configuration.setup_config_values
  end

  def self.configuration
    @configuration ||= Configuration.new(
      prerender_caching: Configuration::DEFAULT_PRERENDER_CACHING,
      server_renderer: Configuration::DEFAULT_RENDERER_METHOD,
      renderer_url: Configuration::DEFAULT_RENDERER_URL,
      renderer_use_fallback_exec_js: Configuration::DEFAULT_RENDERER_FALLBACK_EXEC_JS,
      renderer_http_pool_size: Configuration::DEFAULT_RENDERER_HTTP_POOL_SIZE,
      renderer_http_pool_timeout: Configuration::DEFAULT_RENDERER_HTTP_POOL_TIMEOUT,
      renderer_http_pool_warn_timeout: Configuration::DEFAULT_RENDERER_HTTP_POOL_TIMEOUT,
      renderer_password: nil,
      tracing: Configuration::DEFAULT_TRACING,
      serializer_globs: Configuration::DEFAULT_SERIALIZER_GLOBS,
      ssr_pre_hook_js: nil,
      assets_to_copy: nil,
      renderer_request_retry_limit: Configuration::DEFAULT_RENDERER_REQUEST_RETRY_LIMIT
    )
  end

  class Configuration
    DEFAULT_RENDERER_URL = "http://localhost:3800"
    DEFAULT_RENDERER_METHOD = "ExecJS"
    DEFAULT_RENDERER_FALLBACK_EXEC_JS = true
    DEFAULT_RENDERER_HTTP_POOL_SIZE = 10
    DEFAULT_RENDERER_HTTP_POOL_TIMEOUT = 5
    DEFAULT_RENDERER_HTTP_POOL_WARN_TIMEOUT = 0.25
    DEFAULT_PRERENDER_CACHING = false
    DEFAULT_TRACING = false
    DEFAULT_SERIALIZER_GLOBS = nil
    DEFAULT_RENDERER_REQUEST_RETRY_LIMIT = 5

    attr_accessor :renderer_url, :renderer_password, :tracing,
                  :server_renderer, :renderer_use_fallback_exec_js, :prerender_caching,
                  :renderer_http_pool_size, :renderer_http_pool_timeout, :renderer_http_pool_warn_timeout,
                  :serializer_globs, :ssr_pre_hook_js, :assets_to_copy,
                  :renderer_request_retry_limit

    def initialize(renderer_url: nil, renderer_password: nil, server_renderer: nil,
                   renderer_use_fallback_exec_js: nil, prerender_caching: nil,
                   renderer_http_pool_size: nil, renderer_http_pool_timeout: nil,
                   renderer_http_pool_warn_timeout: nil, tracing: nil,
                   serializer_globs: nil, ssr_pre_hook_js: nil, assets_to_copy: nil,
                   renderer_request_retry_limit: nil)
      self.renderer_url = renderer_url
      self.renderer_password = renderer_password
      self.server_renderer = server_renderer
      self.renderer_use_fallback_exec_js = renderer_use_fallback_exec_js
      self.prerender_caching = prerender_caching
      self.renderer_http_pool_size = renderer_http_pool_size
      self.renderer_http_pool_timeout = renderer_http_pool_timeout
      self.renderer_http_pool_warn_timeout = renderer_http_pool_warn_timeout
      self.tracing = tracing
      self.serializer_globs = serializer_globs
      self.ssr_pre_hook_js = ssr_pre_hook_js
      self.assets_to_copy = assets_to_copy
      self.renderer_request_retry_limit = renderer_request_retry_limit
    end

    def setup_config_values
      configure_default_url_if_not_provided
      validate_url
      setup_renderer_password
      setup_assets_to_copy
    end

    private

    def setup_assets_to_copy
      self.assets_to_copy = (Array(assets_to_copy) if assets_to_copy.present?)
    end

    def configure_default_url_if_not_provided
      self.renderer_url = renderer_url.presence || DEFAULT_RENDERER_URL
    end

    def validate_url
      URI(renderer_url)
    rescue URI::InvalidURIError => e
      message = "Unparseable ReactOnRailsPro.config.renderer_url #{renderer_url} provided.\n#{e.message}"
      raise ReactOnRailsPro::Error, message
    end

    def setup_renderer_password
      return if renderer_password.present?

      begin
        uri = URI(renderer_url)
        self.renderer_password = uri.password
      end
    end
  end
end
