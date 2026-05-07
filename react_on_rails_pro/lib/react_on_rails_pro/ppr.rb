# frozen_string_literal: true

module ReactOnRailsPro
  # Partial Prerendering (PPR) helpers — cache key composition and runtime support checks.
  #
  # PPR caches a Hash of `(shell_html, postponed_state, console_replay_script)` keyed by
  # component + props + bundle digest. On a cache hit the shell streams immediately and only
  # postponed boundaries execute on the server. See `ppr_react_component` in
  # `react_on_rails_pro_helper.rb` for usage.
  module PPR
    # Bump this when the cached shape changes (renames, new fields, semantic changes). The cache
    # key includes this so old cached values are invalidated cleanly on upgrade.
    CACHE_VERSION = 1

    module_function

    # Compose the PPR cache key. Mirrors `ReactOnRailsPro::Cache.react_component_cache_key`
    # (component + bundle digest + dep digest + user cache_key) and adds a 'ror_pro_ppr-vN'
    # namespace so PPR cache entries don't collide with other Pro caches.
    #
    # The effective `ppr_prerender_timeout_ms` is included so changing the timeout invalidates
    # the cache: a different timeout produces a different set of resolved-vs-postponed
    # boundaries in the shell.
    def cache_key(component_name, options)
      timeout = options[:ppr_prerender_timeout_ms] ||
                ReactOnRailsPro.configuration.ppr_prerender_timeout_ms
      [
        "ror_pro_ppr-v#{CACHE_VERSION}",
        "timeout-#{timeout}",
        *ReactOnRailsPro::Cache.react_component_cache_key(component_name, options.merge(prerender: true))
      ]
    end

    # Returns true when PPR helpers can be used in this process. Currently requires:
    #   - `enable_ppr_support` flag in configuration
    #   - the Pro node renderer (ExecJS lacks AbortController/streams)
    def supported?
      ReactOnRailsPro.configuration.enable_ppr_support && ReactOnRailsPro.configuration.node_renderer?
    end

    # Throws a clear error if the runtime can't run PPR.
    def ensure_supported!
      return if supported?

      msg = []
      unless ReactOnRailsPro.configuration.enable_ppr_support
        msg << "Enable it with `config.enable_ppr_support = true` in config/initializers/react_on_rails_pro.rb."
      end
      unless ReactOnRailsPro.configuration.node_renderer?
        msg << "PPR requires the Pro node renderer (ExecJS lacks AbortController/streams). " \
               "Set `config.server_renderer = 'NodeRenderer'`."
      end
      raise ReactOnRailsPro::Error, "PPR is not available: #{msg.join(' ')}"
    end
  end
end
