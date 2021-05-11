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
      dependency_globs: Configuration::DEFAULT_DEPENDENCY_GLOBS,
      excluded_dependency_globs: Configuration::DEFAULT_EXCLUDED_DEPENDENCY_GLOBS,
      remote_bundle_cache_adapter: Configuration::DEFAULT_REMOTE_BUNDLE_CACHE_ADAPTER,
      ssr_pre_hook_js: nil,
      assets_to_copy: nil,
      renderer_request_retry_limit: Configuration::DEFAULT_RENDERER_REQUEST_RETRY_LIMIT,
      throw_js_errors: Configuration::DEFAULT_THROW_JS_ERRORS
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
    DEFAULT_DEPENDENCY_GLOBS = nil
    DEFAULT_EXCLUDED_DEPENDENCY_GLOBS = ["**/node_modules/**/*"].freeze
    DEFAULT_REMOTE_BUNDLE_CACHE_ADAPTER = nil
    DEFAULT_RENDERER_REQUEST_RETRY_LIMIT = 5
    DEFAULT_THROW_JS_ERRORS = false

    attr_accessor :renderer_url, :renderer_password, :tracing,
                  :server_renderer, :renderer_use_fallback_exec_js, :prerender_caching,
                  :renderer_http_pool_size, :renderer_http_pool_timeout, :renderer_http_pool_warn_timeout,
                  :dependency_globs, :excluded_dependency_globs,
                  :remote_bundle_cache_adapter, :ssr_pre_hook_js, :assets_to_copy,
                  :renderer_request_retry_limit, :throw_js_errors

    def initialize(renderer_url: nil, renderer_password: nil, server_renderer: nil,
                   renderer_use_fallback_exec_js: nil, prerender_caching: nil,
                   renderer_http_pool_size: nil, renderer_http_pool_timeout: nil,
                   renderer_http_pool_warn_timeout: nil, tracing: nil,
                   dependency_globs: nil, excluded_dependency_globs: nil,
                   remote_bundle_cache_adapter: nil, ssr_pre_hook_js: nil, assets_to_copy: nil,
                   renderer_request_retry_limit: nil, throw_js_errors: nil)
      self.renderer_url = renderer_url
      self.renderer_password = renderer_password
      self.server_renderer = server_renderer
      self.renderer_use_fallback_exec_js = renderer_use_fallback_exec_js
      self.prerender_caching = prerender_caching
      self.renderer_http_pool_size = renderer_http_pool_size
      self.renderer_http_pool_timeout = renderer_http_pool_timeout
      self.renderer_http_pool_warn_timeout = renderer_http_pool_warn_timeout
      self.tracing = tracing
      self.dependency_globs = dependency_globs
      self.excluded_dependency_globs = excluded_dependency_globs
      self.remote_bundle_cache_adapter = remote_bundle_cache_adapter
      self.ssr_pre_hook_js = ssr_pre_hook_js
      self.assets_to_copy = assets_to_copy
      self.renderer_request_retry_limit = renderer_request_retry_limit
      self.throw_js_errors = throw_js_errors
    end

    def setup_config_values
      configure_default_url_if_not_provided
      validate_url
      validate_remote_bundle_cache_adapter
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

    def validate_remote_bundle_cache_adapter
      if !remote_bundle_cache_adapter.nil? && !remote_bundle_cache_adapter.is_a?(Module)
        raise ReactOnRailsPro::Error, "config.remote_bundle_cache_adapter can only have a module or class assigned"
      end

      return unless remote_bundle_cache_adapter.is_a?(Module)

      unless remote_bundle_cache_adapter.methods.include?(:build)
        raise ReactOnRailsPro::Error,
              "config.remote_bundle_cache_adapter must have a class method named 'build'"
      end

      unless remote_bundle_cache_adapter.methods.include?(:fetch)
        raise ReactOnRailsPro::Error,
              "config.remote_bundle_cache_adapter must have a class method named 'fetch'" \
              "which takes a single named String parameter 'zipped_bundles_filename'" \
              "and returns the zipped file as a string if fetch attempt is successful & nil if not"
      end

      unless remote_bundle_cache_adapter.methods.include?(:upload) # rubocop:disable Style/GuardClause
        raise ReactOnRailsPro::Error,
              "config.remote_bundle_cache_adapter must have a class method named 'upload'" \
              "which takes a single named Pathname parameter 'zipped_bundles_filepath' & returns nil"
      end
    end

    def setup_renderer_password
      return if renderer_password.present?

      uri = URI(renderer_url)
      self.renderer_password = uri.password
    end
  end
end
