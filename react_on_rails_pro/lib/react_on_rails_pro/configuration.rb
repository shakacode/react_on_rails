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
      renderer_http_pool_warn_timeout: Configuration::DEFAULT_RENDERER_HTTP_POOL_WARN_TIMEOUT,
      renderer_password: nil,
      tracing: Configuration::DEFAULT_TRACING,
      dependency_globs: Configuration::DEFAULT_DEPENDENCY_GLOBS,
      excluded_dependency_globs: Configuration::DEFAULT_EXCLUDED_DEPENDENCY_GLOBS,
      remote_bundle_cache_adapter: Configuration::DEFAULT_REMOTE_BUNDLE_CACHE_ADAPTER,
      ssr_timeout: Configuration::DEFAULT_SSR_TIMEOUT,
      ssr_pre_hook_js: nil,
      assets_to_copy: nil,
      renderer_request_retry_limit: Configuration::DEFAULT_RENDERER_REQUEST_RETRY_LIMIT,
      throw_js_errors: Configuration::DEFAULT_THROW_JS_ERRORS,
      rendering_returns_promises: Configuration::DEFAULT_RENDERING_RETURNS_PROMISES,
      profile_server_rendering_js_code: Configuration::DEFAULT_PROFILE_SERVER_RENDERING_JS_CODE,
      raise_non_shell_server_rendering_errors: Configuration::DEFAULT_RAISE_NON_SHELL_SERVER_RENDERING_ERRORS,
      enable_rsc_support: Configuration::DEFAULT_ENABLE_RSC_SUPPORT,
      rsc_payload_generation_url_path: Configuration::DEFAULT_RSC_PAYLOAD_GENERATION_URL_PATH,
      rsc_bundle_js_file: Configuration::DEFAULT_RSC_BUNDLE_JS_FILE,
      react_client_manifest_file: Configuration::DEFAULT_REACT_CLIENT_MANIFEST_FILE,
      react_server_client_manifest_file: Configuration::DEFAULT_REACT_SERVER_CLIENT_MANIFEST_FILE,
      concurrent_stream_drain: Configuration::DEFAULT_CONCURRENT_STREAM_DRAIN
    )
  end

  class Configuration # rubocop:disable Metrics/ClassLength
    DEFAULT_RENDERER_URL = "http://localhost:3800"
    DEFAULT_RENDERER_METHOD = "ExecJS"
    DEFAULT_RENDERER_FALLBACK_EXEC_JS = true
    DEFAULT_RENDERER_HTTP_POOL_SIZE = 10
    DEFAULT_RENDERER_HTTP_POOL_TIMEOUT = 5
    DEFAULT_RENDERER_HTTP_POOL_WARN_TIMEOUT = 0.25
    DEFAULT_SSR_TIMEOUT = 5
    DEFAULT_PRERENDER_CACHING = false
    DEFAULT_TRACING = false
    DEFAULT_DEPENDENCY_GLOBS = [].freeze
    DEFAULT_EXCLUDED_DEPENDENCY_GLOBS = [].freeze
    DEFAULT_REMOTE_BUNDLE_CACHE_ADAPTER = nil
    DEFAULT_RENDERER_REQUEST_RETRY_LIMIT = 5
    DEFAULT_THROW_JS_ERRORS = true
    DEFAULT_RENDERING_RETURNS_PROMISES = false
    DEFAULT_PROFILE_SERVER_RENDERING_JS_CODE = false
    DEFAULT_RAISE_NON_SHELL_SERVER_RENDERING_ERRORS = false
    DEFAULT_ENABLE_RSC_SUPPORT = false
    DEFAULT_RSC_PAYLOAD_GENERATION_URL_PATH = "rsc_payload/"
    DEFAULT_RSC_BUNDLE_JS_FILE = "rsc-bundle.js"
    DEFAULT_REACT_CLIENT_MANIFEST_FILE = "react-client-manifest.json"
    DEFAULT_REACT_SERVER_CLIENT_MANIFEST_FILE = "react-server-client-manifest.json"
    DEFAULT_CONCURRENT_STREAM_DRAIN = false

    attr_accessor :renderer_url, :renderer_password, :tracing,
                  :server_renderer, :renderer_use_fallback_exec_js, :prerender_caching,
                  :renderer_http_pool_size, :renderer_http_pool_timeout, :renderer_http_pool_warn_timeout,
                  :dependency_globs, :excluded_dependency_globs, :rendering_returns_promises,
                  :remote_bundle_cache_adapter, :ssr_pre_hook_js, :assets_to_copy,
                  :renderer_request_retry_limit, :throw_js_errors, :ssr_timeout,
                  :profile_server_rendering_js_code, :raise_non_shell_server_rendering_errors, :enable_rsc_support,
                  :rsc_payload_generation_url_path, :rsc_bundle_js_file, :react_client_manifest_file,
                  :react_server_client_manifest_file, :concurrent_stream_drain

    def initialize(renderer_url: nil, renderer_password: nil, server_renderer: nil, # rubocop:disable Metrics/AbcSize
                   renderer_use_fallback_exec_js: nil, prerender_caching: nil,
                   renderer_http_pool_size: nil, renderer_http_pool_timeout: nil,
                   renderer_http_pool_warn_timeout: nil, tracing: nil,
                   dependency_globs: nil, excluded_dependency_globs: nil, rendering_returns_promises: nil,
                   remote_bundle_cache_adapter: nil, ssr_pre_hook_js: nil, assets_to_copy: nil,
                   renderer_request_retry_limit: nil, throw_js_errors: nil, ssr_timeout: nil,
                   profile_server_rendering_js_code: nil, raise_non_shell_server_rendering_errors: nil,
                   enable_rsc_support: nil, rsc_payload_generation_url_path: nil,
                   rsc_bundle_js_file: nil, react_client_manifest_file: nil,
                   react_server_client_manifest_file: nil,
                   concurrent_stream_drain: DEFAULT_CONCURRENT_STREAM_DRAIN)
      self.renderer_url = renderer_url
      self.renderer_password = renderer_password
      self.server_renderer = server_renderer
      self.renderer_use_fallback_exec_js = renderer_use_fallback_exec_js
      self.prerender_caching = prerender_caching
      self.renderer_http_pool_size = renderer_http_pool_size
      self.renderer_http_pool_timeout = renderer_http_pool_timeout
      self.renderer_http_pool_warn_timeout = renderer_http_pool_warn_timeout
      self.tracing = tracing
      self.rendering_returns_promises = server_renderer == "NodeRenderer" ? rendering_returns_promises : false
      self.dependency_globs = dependency_globs
      self.excluded_dependency_globs = excluded_dependency_globs
      self.remote_bundle_cache_adapter = remote_bundle_cache_adapter
      self.ssr_pre_hook_js = ssr_pre_hook_js
      self.assets_to_copy = assets_to_copy
      self.renderer_request_retry_limit = renderer_request_retry_limit
      self.throw_js_errors = throw_js_errors
      self.ssr_timeout = ssr_timeout
      self.profile_server_rendering_js_code = profile_server_rendering_js_code
      self.raise_non_shell_server_rendering_errors = raise_non_shell_server_rendering_errors
      self.enable_rsc_support = enable_rsc_support
      self.rsc_payload_generation_url_path = rsc_payload_generation_url_path
      self.rsc_bundle_js_file = rsc_bundle_js_file
      self.react_client_manifest_file = react_client_manifest_file
      self.react_server_client_manifest_file = react_server_client_manifest_file
      self.concurrent_stream_drain = concurrent_stream_drain
    end

    def setup_config_values
      configure_default_url_if_not_provided
      validate_url
      validate_remote_bundle_cache_adapter
      setup_renderer_password
      setup_assets_to_copy
      setup_execjs_profiler_if_needed
      check_react_on_rails_support_for_rsc
    end

    def check_react_on_rails_support_for_rsc
      return unless enable_rsc_support

      return if ReactOnRails::Utils.respond_to?(:rsc_support_enabled?)

      raise ReactOnRailsPro::Error, <<~MSG
        React Server Components (RSC) support requires react_on_rails version 15.0.0 or higher.
        Please upgrade your react_on_rails gem to enable this feature.
      MSG
    end

    def setup_execjs_profiler_if_needed
      return unless profile_server_rendering_js_code && server_renderer == "ExecJS"

      if ExecJS.runtime == ExecJS::Runtimes::Node
        ExecJS.runtime = ExecJS::ExternalRuntime.new(
          name: "Node.js (V8)",
          command: ["node --prof"],
          runner_path: "#{ExecJS.root}/support/node_runner.js",
          encoding: "UTF-8"
        )
      elsif ExecJS.runtime == ExecJS::Runtimes::V8
        ExecJS.runtime = ExecJS::ExternalRuntime.new(
          name: "V8",
          command: ["d8 --prof"],
          runner_path: "#{ExecJS.root}/support/v8_runner.js",
          encoding: "UTF-8"
        )
      else
        current_runtime = ExecJS.runtime.name
        message = <<~MSG
          You have set `profile_server_rendering_js_code` to true, but the current execjs runtime is #{current_runtime}.
          ExecJS profiler only supports Node.js (V8) or V8 runtimes.
          You can set the runtime by setting the `EXECJS_RUNTIME` environment variable to either `Node` or `V8`.
        MSG
        raise ReactOnRailsPro::Error, message
      end
    end

    def node_renderer?
      ReactOnRailsPro.configuration.server_renderer == "NodeRenderer"
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
      message = "Unparseable ReactOnRailsPro.config.renderer_url #{renderer_url} provided.\n" \
                "#{e.message}"
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
