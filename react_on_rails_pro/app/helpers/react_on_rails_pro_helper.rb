# frozen_string_literal: true

# NOTE: For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var

require "react_on_rails/helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRailsProHelper
  def fetch_react_component(component_name, options)
    if ReactOnRailsPro::Cache.use_cache?(options)
      cache_key = ReactOnRailsPro::Cache.react_component_cache_key(component_name, options)
      Rails.logger.debug { "React on Rails Pro cache_key is #{cache_key.inspect}" }
      cache_options = options[:cache_options]
      cache_hit = true
      result = Rails.cache.fetch(cache_key, cache_options) do
        cache_hit = false
        yield
      end
      if cache_hit
        render_options = ReactOnRails::ReactComponent::RenderOptions.new(
          react_component_name: component_name,
          options: options
        )
        load_pack_for_generated_component(component_name, render_options)
      end
      # Pass back the cache key in the results only if the result is a Hash
      if result.is_a?(Hash)
        result[:RORP_CACHE_KEY] = cache_key
        result[:RORP_CACHE_HIT] = cache_hit
      end
      result
    else
      yield
    end
  end

  # Provide caching support for react_component in a manner akin to Rails fragment caching.
  # All the same options as react_component apply with the following difference:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #    cache_key: String or Array (or Proc returning a String or Array) containing your cache keys.
  #    If prerender is set to true, the server bundle digest will be included in the cache key.
  #    The cache_key value is the same as used for conventional Rails fragment caching.
  # 3. Optionally provide the `:cache_options` key with a value of a hash including as
  #    :compress, :expires_in, :race_condition_ttl as documented in the Rails Guides
  # 4. Provide boolean values for `:if` or `:unless` to conditionally use caching.
  def cached_react_component(component_name, raw_options = {}, &block)
    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)

      fetch_react_component(component_name, raw_options) do
        sanitized_options = raw_options
        sanitized_options[:props] = yield
        sanitized_options[:skip_prerender_cache] = true
        sanitized_options[:auto_load_bundle] =
          ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]
        react_component(component_name, sanitized_options)
      end
    end
  end

  # Provide caching support for react_component_hash in a manner akin to Rails fragment caching.
  # All the same options as react_component_hash apply with the following difference:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #    cache_key: String or Array (or Proc returning a String or Array) containing your cache keys.
  #    Since prerender is automatically set to true, the server bundle digest will be included in the cache key.
  #    The cache_key value is the same as used for conventional Rails fragment caching.
  # 3. Optionally provide the `:cache_options` key with a value of a hash including as
  #    :compress, :expires_in, :race_condition_ttl as documented in the Rails Guides
  # 4. Provide boolean values for `:if` or `:unless` to conditionally use caching.
  def cached_react_component_hash(component_name, raw_options = {}, &block)
    raw_options[:prerender] = true

    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)

      fetch_react_component(component_name, raw_options) do
        sanitized_options = raw_options
        sanitized_options[:props] = yield
        sanitized_options[:skip_prerender_cache] = true
        sanitized_options[:auto_load_bundle] =
          ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]
        react_component_hash(component_name, sanitized_options)
      end
    end
  end

  # Streams a server-side rendered React component using React's `renderToPipeableStream`.
  # Supports React 18 features like Suspense, concurrent rendering, and selective hydration.
  # Enables progressive rendering and improved performance for large components.
  #
  # Note: This function can only be used with React on Rails Pro.
  # The view that uses this function must be rendered using the
  # `stream_view_containing_react_components` method from the React on Rails Pro gem.
  #
  # Example of an async React component that can benefit from streaming:
  #
  # const AsyncComponent = async () => {
  #   const data = await fetchData();
  #   return <div>{data}</div>;
  # };
  #
  # function App() {
  #   return (
  #     <Suspense fallback={<div>Loading...</div>}>
  #       <AsyncComponent />
  #     </Suspense>
  #   );
  # }
  #
  # @param [String] component_name Name of your registered component
  # @param [Hash] options Options for rendering
  # @option options [Hash] :props Props to pass to the react component
  # @option options [String] :dom_id DOM ID of the component container
  # @option options [Hash] :html_options Options passed to content_tag
  # @option options [Boolean] :trace Set to true to add extra debugging information to the HTML
  # @option options [Boolean] :raise_on_prerender_error Set to true to raise exceptions during server-side rendering
  # Any other options are passed to the content tag, including the id.
  def stream_react_component(component_name, options = {})
    # stream_react_component doesn't have the prerender option
    # Because setting prerender to false is equivalent to calling react_component with prerender: false
    options[:prerender] = true
    options = options.merge(immediate_hydration: true) unless options.key?(:immediate_hydration)
    run_stream_inside_fiber do
      internal_stream_react_component(component_name, options)
    end
  end

  # Renders the React Server Component (RSC) payload for a given component. This helper generates
  # a special format designed by React for serializing server components and transmitting them
  # to the client.
  #
  # @return [String] Returns a Newline Delimited JSON (NDJSON) stream where each line contains a JSON object with:
  #   - html: The RSC payload containing the rendered server components and client component references
  #   - consoleReplayScript: JavaScript to replay server-side console logs in the client
  #   - hasErrors: Boolean indicating if any errors occurred during rendering
  #   - isShellReady: Boolean indicating if the initial shell is ready for hydration
  #
  # Example NDJSON stream:
  #   {"html":"<RSC Payload>","consoleReplayScript":"","hasErrors":false,"isShellReady":true}
  #   {"html":"<RSC Payload>","consoleReplayScript":"console.log('Loading...')","hasErrors":false,"isShellReady":true}
  #
  # The RSC payload within the html field contains:
  # - The component's rendered output from the server
  # - References to client components that need hydration
  # - Data props passed to client components
  #
  # @param component_name [String] The name of the React component to render. This component should
  #   be a server component or a mixed component tree containing both server and client components.
  #
  # @param options [Hash] Options for rendering the component
  # @option options [Hash] :props Props to pass to the component (default: {})
  # @option options [Boolean] :trace Enable tracing for debugging (default: false)
  # @option options [String] :id Custom DOM ID for the component container (optional)
  #
  # @example Basic usage with a server component
  #   <%= rsc_payload_react_component("ReactServerComponentPage") %>
  #
  # @example With props and tracing enabled
  #   <%= rsc_payload_react_component("RSCPostsPage",
  #         props: { artificialDelay: 1000 },
  #         trace: true) %>
  #
  # @note This helper requires React Server Components support to be enabled in your configuration:
  #   ReactOnRailsPro.configure do |config|
  #     config.enable_rsc_support = true
  #   end
  #
  # @raise [ReactOnRailsPro::Error] if RSC support is not enabled in configuration
  #
  # @note You don't have to deal directly with this helper function - it's used internally by the
  # `rsc_payload_route` helper function. The returned data from this function is used internally by
  # components registered using the `registerServerComponent` function. Don't use it unless you need
  # more control over the RSC payload generation. To know more about RSC payload, see the following link:
  # @see https://www.shakacode.com/react-on-rails-pro/docs/how-react-server-components-works.md
  #   for technical details about the RSC payload format
  def rsc_payload_react_component(component_name, options = {})
    # rsc_payload_react_component doesn't have the prerender option
    # Because setting prerender to false will not do anything
    options[:prerender] = true
    run_stream_inside_fiber do
      internal_rsc_payload_react_component(component_name, options)
    end
  end

  # Provide caching support for stream_react_component in a manner akin to Rails fragment caching.
  # All the same options as stream_react_component apply with the following differences:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #    cache_key: String or Array (or Proc returning a String or Array) containing your cache keys.
  #    Since prerender is automatically set to true, the server bundle digest will be included in the cache key.
  #    The cache_key value is the same as used for conventional Rails fragment caching.
  # 3. Optionally provide the `:cache_options` key with a value of a hash including as
  #    :compress, :expires_in, :race_condition_ttl as documented in the Rails Guides
  # 4. Provide boolean values for `:if` or `:unless` to conditionally use caching.
  def cached_stream_react_component(component_name, raw_options = {}, &block)
    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)
      fetch_stream_react_component(component_name, raw_options, &block)
    end
  end

  if defined?(ScoutApm)
    include ScoutApm::Tracer
    instrument_method :cached_react_component, type: "ReactOnRails", name: "cached_react_component"
    instrument_method :cached_react_component_hash, type: "ReactOnRails", name: "cached_react_component_hash"
    instrument_method :cached_stream_react_component, type: "ReactOnRails", name: "cached_stream_react_component"
  end

  private

  def fetch_stream_react_component(component_name, raw_options, &block)
    auto_load_bundle = ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]

    unless ReactOnRailsPro::Cache.use_cache?(raw_options)
      return render_stream_component_with_props(component_name, raw_options, auto_load_bundle, &block)
    end

    # Compose a cache key consistent with non-stream helper semantics.
    key_options = raw_options.merge(prerender: true)
    view_cache_key = ReactOnRailsPro::Cache.react_component_cache_key(component_name, key_options)

    # Attempt HIT without evaluating props block
    if (cached_chunks = Rails.cache.read(view_cache_key)).is_a?(Array)
      return handle_stream_cache_hit(component_name, raw_options, auto_load_bundle, cached_chunks)
    end

    # MISS: evaluate props lazily, stream live, and write-through to view-level cache
    handle_stream_cache_miss(component_name, raw_options, auto_load_bundle, view_cache_key, &block)
  end

  def handle_stream_cache_hit(component_name, raw_options, auto_load_bundle, cached_chunks)
    render_options = ReactOnRails::ReactComponent::RenderOptions.new(
      react_component_name: component_name,
      options: { auto_load_bundle: auto_load_bundle }.merge(raw_options)
    )
    load_pack_for_generated_component(component_name, render_options)

    initial_result, *rest_chunks = cached_chunks
    hit_fiber = Fiber.new do
      rest_chunks.each { |chunk| Fiber.yield(chunk) }
      nil
    end
    @rorp_rendering_fibers << hit_fiber
    initial_result
  end

  def handle_stream_cache_miss(component_name, raw_options, auto_load_bundle, view_cache_key, &block)
    # Kick off the normal streaming helper to get the initial result and the original fiber
    initial_result = render_stream_component_with_props(component_name, raw_options, auto_load_bundle, &block)
    original_fiber = @rorp_rendering_fibers.pop

    buffered_chunks = [initial_result]
    wrapper_fiber = Fiber.new do
      while (chunk = original_fiber.resume)
        buffered_chunks << chunk
        Fiber.yield(chunk)
      end
      Rails.cache.write(view_cache_key, buffered_chunks, raw_options[:cache_options] || {})
      nil
    end
    @rorp_rendering_fibers << wrapper_fiber
    initial_result
  end

  def render_stream_component_with_props(component_name, raw_options, auto_load_bundle)
    props = yield
    options = raw_options.merge(
      props: props,
      prerender: true,
      skip_prerender_cache: true,
      auto_load_bundle: auto_load_bundle
    )
    stream_react_component(component_name, options)
  end

  def check_caching_options!(raw_options, block)
    raise ReactOnRailsPro::Error, "Pass 'props' as a block if using caching" if raw_options.key?(:props) || block.nil?

    return if raw_options.key?(:cache_key)

    raise ReactOnRailsPro::Error, "Option 'cache_key' is required for React on Rails caching"
  end

  def run_stream_inside_fiber
    require "async/variable"

    if @async_barrier.nil?
      raise ReactOnRails::Error,
            "You must call stream_view_containing_react_components to render the view containing the react component"
    end

    # Create a variable to hold the first chunk for synchronous return
    first_chunk_var = Async::Variable.new

    # Start an async task on the barrier to stream all chunks
    @async_barrier.async do
      stream = yield
      is_first = true

      stream.each_chunk do |chunk|
        if is_first
          # Store first chunk in variable for synchronous access
          first_chunk_var.value = chunk
          is_first = false
        else
          # Enqueue remaining chunks to main output queue
          @main_output_queue.enqueue(chunk)
        end
      end

      # Handle case where stream has no chunks
      first_chunk_var.value = nil if is_first
    end

    # Wait for and return the first chunk (blocking)
    first_chunk_var.wait
    first_chunk_var.value
  end

  def internal_stream_react_component(component_name, options = {})
    options = options.merge(render_mode: :html_streaming)
    result = internal_react_component(component_name, options)
    build_react_component_result_for_server_streamed_content(
      rendered_html_stream: result[:result],
      component_specification_tag: result[:tag],
      render_options: result[:render_options]
    )
  end

  def internal_rsc_payload_react_component(react_component_name, options = {})
    options = options.merge(render_mode: :rsc_payload_streaming)
    render_options = create_render_options(react_component_name, options)
    json_stream = server_rendered_react_component(render_options)
    json_stream.transform do |chunk|
      "#{chunk.to_json}\n".html_safe
    end
  end

  def build_react_component_result_for_server_streamed_content(
    rendered_html_stream:,
    component_specification_tag:,
    render_options:
  )
    is_first_chunk = true
    rendered_html_stream.transform do |chunk_json_result|
      if is_first_chunk
        is_first_chunk = false
        build_react_component_result_for_server_rendered_string(
          server_rendered_html: chunk_json_result["html"],
          component_specification_tag: component_specification_tag,
          console_script: chunk_json_result["consoleReplayScript"],
          render_options: render_options
        )
      else
        console_script = chunk_json_result["consoleReplayScript"]
        result_console_script = render_options.replay_console ? wrap_console_script_with_nonce(console_script) : ""
        # No need to prepend component_specification_tag or add rails context again
        # as they're already included in the first chunk
        compose_react_component_html_with_spec_and_console(
          "", chunk_json_result["html"], result_console_script
        )
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
