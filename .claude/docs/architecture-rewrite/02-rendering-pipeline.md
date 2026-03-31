# New Architecture: Rendering Pipeline (Ruby Side)

## Design Principle

Replace runtime `react_on_rails_pro?` checks with a **strategy pattern** where the rendering backend is configured once at boot time and injected via a well-defined interface.

## Current vs Proposed

### Current: Conditional Delegation

```ruby
# Called on every render
def pool
  @pool ||= if ReactOnRails::Utils.react_on_rails_pro?
              ReactOnRailsPro::ServerRenderingPool::ProRendering
            else
              ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript
            end
end
```

### Proposed: Strategy Registration at Boot

```ruby
# Called once at boot time in engine initializer
ReactOnRails.rendering_strategy = ReactOnRailsPro::NodeRenderingStrategy.new
# OR (if Pro not installed):
ReactOnRails.rendering_strategy = ReactOnRails::ExecJSRenderingStrategy.new
```

## The RenderingStrategy Interface

Define a single interface that both core and Pro implement:

```ruby
module ReactOnRails
  module RenderingStrategy
    # Execute JS code for SSR and return a result hash or stream.
    #
    # @param render_request [RenderRequest] Structured render request
    # @return [Hash] { "html" => String, "consoleReplayScript" => String, "hasErrors" => Boolean }
    #   OR a StreamDecorator for streaming renders
    def execute(render_request)
      raise NotImplementedError
    end

    # Reset the rendering pool (e.g., on bundle change in development)
    def reset
      raise NotImplementedError
    end

    # Check if the bundle has changed and reset if needed
    def reset_if_bundle_changed
      raise NotImplementedError
    end
  end
end
```

## Concrete Strategies

### ExecJSRenderingStrategy (Core)

Replaces `RubyEmbeddedJavaScript`. Same ExecJS connection pool logic, but packaged as a strategy:

```ruby
module ReactOnRails
  class ExecJSRenderingStrategy
    include RenderingStrategy

    def initialize
      @pool = nil
    end

    def execute(render_request)
      js_code = render_request.to_js
      result_string = with_js_context { |ctx| ctx.eval(js_code) }
      parse_result(result_string)
    end

    def reset
      @pool = nil
    end

    def reset_if_bundle_changed
      # Check file mtime, reset pool if changed (existing logic)
    end

    private

    def with_js_context(&block)
      ensure_pool_initialized
      @pool.with(&block)
    end
  end
end
```

### NodeRenderingStrategy (Pro)

Replaces `ProRendering` + `NodeRenderingPool`. Handles caching, Node HTTP communication, and fallback in one class:

```ruby
module ReactOnRailsPro
  class NodeRenderingStrategy
    include ReactOnRails::RenderingStrategy

    def initialize(config: ReactOnRailsPro.configuration)
      @config = config
      @fallback = ReactOnRails::ExecJSRenderingStrategy.new
    end

    def execute(render_request)
      if render_request.streaming?
        execute_streaming(render_request)
      elsif @config.prerender_caching
        execute_with_cache(render_request)
      else
        execute_on_node(render_request)
      end
    rescue StandardError => e
      raise e unless @config.renderer_use_fallback_exec_js
      @fallback.execute(render_request)
    end

    def reset
      ReactOnRailsPro::Request.reset_connection
    end

    def reset_if_bundle_changed
      # Existing bundle hash check logic
    end

    private

    def execute_on_node(render_request)
      response = ReactOnRailsPro::Request.render(render_request)
      handle_response(response, render_request)
    end

    def execute_streaming(render_request)
      ReactOnRailsPro::Request.render_stream(render_request)
    end

    def execute_with_cache(render_request)
      cache_key = render_request.cache_key
      Rails.cache.fetch(cache_key) { execute_on_node(render_request) }
    end

    def handle_response(response, render_request)
      case response.status
      when 200 then response.body
      when 410 then execute_with_bundle(render_request)
      else raise ReactOnRailsPro::Error, "Renderer error: #{response.status}"
      end
    end
  end
end
```

## The RenderRequest Object

Replace string-built JS with a structured request object that strategies can serialize as needed.

```ruby
module ReactOnRails
  class RenderRequest
    attr_reader :component_name, :props, :rails_context,
                :store_initializations, :render_options, :dom_id

    def initialize(component_name:, props:, rails_context:,
                   store_initializations:, render_options:)
      @component_name = component_name
      @props = props
      @rails_context = rails_context
      @store_initializations = store_initializations
      @render_options = render_options
      @dom_id = render_options.dom_id
    end

    # Serialize to JS code for ExecJS execution
    def to_js
      js_code_builder.build(self)
    end

    # Serialize to JSON for Node renderer HTTP request
    def to_json_payload
      {
        componentName: @component_name,
        props: @props,
        railsContext: @rails_context,
        stores: @store_initializations.map(&:to_h),
        domNodeId: @dom_id,
        renderMode: @render_options.render_mode,
        trace: @render_options.trace
      }
    end

    # Cache key for prerender caching
    def cache_key
      @cache_key ||= Digest::MD5.hexdigest(to_json_payload.to_json)
    end

    def streaming?
      @render_options.streaming?
    end

    private

    def js_code_builder
      ReactOnRails.js_code_builder
    end
  end
end
```

## How the Helper Changes

The `server_rendered_react_component` method becomes much simpler:

```ruby
# BEFORE (68 lines with nested conditionals)
def server_rendered_react_component(render_options)
  return { "html" => "", "consoleReplayScript" => "" } unless render_options.prerender
  # ... 60+ lines of JS code generation, pool management,
  # error handling, streaming checks ...
end

# AFTER (~20 lines, delegation to strategy)
def server_rendered_react_component(render_options)
  return { "html" => "", "consoleReplayScript" => "" } unless render_options.prerender

  render_request = build_render_request(render_options)

  strategy = ReactOnRails.rendering_strategy
  strategy.reset_if_bundle_changed

  result = strategy.execute(render_request)
  validate_and_wrap_result(result, render_request, render_options)
rescue StandardError => err
  raise ReactOnRails::PrerenderError.new(
    component_name: render_options.react_component_name,
    props: sanitized_props_string(render_options.props),
    err: err,
    js_code: render_request&.to_js
  )
end

def build_render_request(render_options)
  RenderRequest.new(
    component_name: render_options.react_component_name,
    props: render_options.props,
    rails_context: rails_context(server_side: true),
    store_initializations: store_initializations_for(render_options),
    render_options: render_options
  )
end
```

## Eliminating ProHelper Mixin

### Current: Include-based override

```ruby
module Helper
  include ReactOnRails::ProHelper  # silently overrides methods
end
```

### Proposed: Configurable component script generators

Instead of `ProHelper` overriding `generate_component_script` and `generate_store_script`, these become configurable:

```ruby
# In core configuration
ReactOnRails.configure do |config|
  config.component_script_generator = ReactOnRails::DefaultComponentScriptGenerator
  config.store_script_generator = ReactOnRails::DefaultStoreScriptGenerator
end

# Pro overrides at boot time
ReactOnRails.configure do |config|
  config.component_script_generator = ReactOnRailsPro::ImmediateHydrationComponentScriptGenerator
  config.store_script_generator = ReactOnRailsPro::ImmediateHydrationStoreScriptGenerator
end
```

The generators implement a simple interface:

```ruby
module ReactOnRails
  class DefaultComponentScriptGenerator
    def generate(render_options, view_context)
      view_context.content_tag(:script,
        json_safe_and_pretty(render_options.client_props).html_safe,
        type: "application/json",
        class: "js-react-on-rails-component",
        # ... existing attributes ...
      )
    end
  end
end

module ReactOnRailsPro
  class ImmediateHydrationComponentScriptGenerator < ReactOnRails::DefaultComponentScriptGenerator
    def generate(render_options, view_context)
      base_tag = super  # Reuse core logic
      return base_tag unless render_options.immediate_hydration

      # Append immediate hydration script
      immediate_script = build_immediate_hydration_script(render_options, view_context)
      "#{base_tag}\n#{immediate_script}".html_safe
    end
  end
end
```

This gives us:

- **Explicit extension point**: It's clear what can be customized
- **Composition over replacement**: Pro wraps core behavior via `super`
- **No runtime checks**: The generator is set once at configuration time

## Registration Flow

### At boot time (engine initializers):

```ruby
# react_on_rails/engine.rb
initializer "react_on_rails.setup_defaults" do
  ReactOnRails.rendering_strategy ||= ReactOnRails::ExecJSRenderingStrategy.new
  ReactOnRails.js_code_builder ||= ReactOnRails::JsCodeBuilder.new
end

# react_on_rails_pro/engine.rb (runs after core, due to dependency)
initializer "react_on_rails_pro.setup_strategy" do
  if ReactOnRailsPro.configuration.node_renderer?
    ReactOnRails.rendering_strategy = ReactOnRailsPro::NodeRenderingStrategy.new
  end
  ReactOnRails.js_code_builder = ReactOnRailsPro::JsCodeBuilder.new
end
```

### Result

- Zero runtime `react_on_rails_pro?` checks
- Strategies are testable in isolation
- Adding a new strategy (e.g., Bun renderer, Deno renderer) requires zero core changes
- Pro configures core at boot via explicit, visible setup code

## Summary of Ruby-Side Changes

| Current                                              | Proposed                                            | Files Affected                                   |
| ---------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------ |
| `ServerRenderingPool` module with runtime dispatch   | `RenderingStrategy` interface + concrete strategies | server_rendering_pool.rb → strategy classes      |
| `ServerRenderingJsCode` module with runtime dispatch | `JsCodeBuilder` (see doc 03)                        | server_rendering_js_code.rb → builder classes    |
| `ProHelper` mixin overriding core methods            | Configurable script generators                      | pro_helper.rb → generator classes                |
| `ProRendering` delegating to pool with caching       | `NodeRenderingStrategy` encapsulating full flow     | pro_rendering.rb → strategy class                |
| `RenderOptions` with Pro config lookups              | `RenderRequest` as structured data object           | render_options.rb stays, render_request.rb added |
| `helper.rb` 68-line monolithic render method         | ~20-line method delegating to strategy              | helper.rb simplified                             |
