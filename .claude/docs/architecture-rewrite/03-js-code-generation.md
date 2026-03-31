# New Architecture: Structured JS Code Generation

## Design Principle

Replace Ruby heredoc string-building with a **structured builder** that produces JS code from data. The builder can be swapped by Pro to add RSC/streaming support without duplicating the base template.

## Current Problem Recap

Core generates JS like:

```ruby
<<-JS
(function() {
  var railsContext = #{rails_context};
  #{redux_stores}
  var props = #{props_string};
  return ReactOnRails.serverRenderReactComponent({...});
})()
JS
```

Pro generates a completely different IIFE with parameters, RSC function injection, dynamic render function name selection, and regex-based dispatch. The two share no structure.

## Proposed: JsCodeBuilder

### Core Builder

```ruby
module ReactOnRails
  class JsCodeBuilder
    # Builds JS code from a structured RenderRequest.
    #
    # @param render_request [RenderRequest]
    # @return [String] JavaScript IIFE that returns a render result
    def build(render_request)
      sections = []
      sections << rails_context_section(render_request)
      sections << store_initialization_section(render_request)
      sections << props_section(render_request)
      sections << render_call_section(render_request)

      wrap_in_iife(sections.join("\n"))
    end

    protected

    # Each section is a hook point that Pro can override

    def rails_context_section(req)
      "var railsContext = #{req.rails_context.to_json};"
    end

    def store_initialization_section(req)
      return "ReactOnRails.clearHydratedStores();" if req.store_initializations.empty?

      lines = ["ReactOnRails.clearHydratedStores();"]
      lines << "var reduxProps, store, storeGenerator;"
      req.store_initializations.each do |store|
        lines << <<~JS.strip
          reduxProps = #{store[:props].to_json};
          storeGenerator = ReactOnRails.getStoreGenerator(#{store[:name].to_json});
          store = storeGenerator(reduxProps, railsContext);
          ReactOnRails.setStore(#{store[:name].to_json}, store);
        JS
      end
      lines.join("\n")
    end

    def props_section(req)
      "var props = #{safe_json(req.props)};"
    end

    def render_call_section(req)
      <<~JS.strip
        return ReactOnRails.serverRenderReactComponent({
          name: #{req.component_name.to_json},
          domNodeId: #{req.dom_id.to_json},
          props: props,
          trace: #{req.render_options.trace},
          railsContext: railsContext
        });
      JS
    end

    def wrap_in_iife(body)
      "(function() {\n#{body}\n})()"
    end

    private

    def safe_json(value)
      json = value.is_a?(String) ? value : value.to_json
      json.gsub("\u2028", '\u2028').gsub("\u2029", '\u2029')
    end
  end
end
```

### Pro Builder (extends Core via inheritance)

```ruby
module ReactOnRailsPro
  class JsCodeBuilder < ReactOnRails::JsCodeBuilder
    protected

    # Override: Add RSC manifest info to rails context
    def rails_context_section(req)
      base = super
      return base unless rsc_streaming?(req)

      config = ReactOnRailsPro.configuration
      base + <<~JS

        railsContext.reactClientManifestFileName = #{config.react_client_manifest_file.to_json};
        railsContext.reactServerClientManifestFileName = #{config.react_server_client_manifest_file.to_json};
      JS
    end

    # Override: Add pre-hook JS and RSC payload generation
    def store_initialization_section(req)
      base = super
      sections = [base]

      sections << rsc_payload_function(req) if rsc_streaming?(req)
      sections << ssr_pre_hook if ssr_pre_hook.present?

      sections.join("\n")
    end

    # Override: Use dynamic render function name for RSC support
    def render_call_section(req)
      if rsc_streaming?(req)
        rsc_render_call(req)
      else
        super_with_pro_options(req)
      end
    end

    # Override: Parametric IIFE for RSC component/props replacement
    def wrap_in_iife(body)
      # Pro wraps with parameters so generateRSCPayload can call
      # the same IIFE with different component name and props
      "(function(componentName, props) {\n#{body}\n})()"
    end

    private

    def rsc_streaming?(req)
      ReactOnRailsPro.configuration.enable_rsc_support && req.render_options.streaming?
    end

    def rsc_payload_function(req)
      return rsc_payload_guard if req.render_options.rsc_payload_streaming?

      <<~JS
        railsContext.serverSideRSCPayloadParameters = {
          renderingRequest,
          rscBundleHash: #{ReactOnRailsPro::Utils.rsc_bundle_hash.to_json},
        };
        if (typeof generateRSCPayload !== 'function') {
          globalThis.generateRSCPayload = function generateRSCPayload(componentName, props, railsContext) {
            const { renderingRequest, rscBundleHash } = railsContext.serverSideRSCPayloadParameters;
            const propsString = JSON.stringify(props);
            const newRenderingRequest = renderingRequest.replace(
              /\\(\\s*\\)\\s*$/,
              function() { return `(${JSON.stringify(componentName)}, ${propsString})`; }
            );
            return runOnOtherBundle(rscBundleHash, newRenderingRequest);
          }
        }
      JS
    end

    def rsc_payload_guard
      <<~JS
        if (typeof generateRSCPayload !== 'function') {
          globalThis.generateRSCPayload = function generateRSCPayload() {
            throw new Error('The rendering request is already running on the RSC bundle.');
          }
        }
      JS
    end

    def rsc_render_call(req)
      <<~JS.strip
        var renderFn = ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent';
        return ReactOnRails[renderFn]({
          name: componentName || #{req.component_name.to_json},
          domNodeId: #{req.dom_id.to_json},
          props: props || #{safe_json(req.props)},
          trace: #{req.render_options.trace},
          railsContext: railsContext,
          throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
          renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises}
        });
      JS
    end

    def super_with_pro_options(req)
      <<~JS.strip
        return ReactOnRails.serverRenderReactComponent({
          name: #{req.component_name.to_json},
          domNodeId: #{req.dom_id.to_json},
          props: props,
          trace: #{req.render_options.trace},
          railsContext: railsContext,
          throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
          renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises}
        });
      JS
    end

    def ssr_pre_hook
      ReactOnRailsPro.configuration.ssr_pre_hook_js || ""
    end
  end
end
```

## Benefits

### 1. Shared structure, divergent behavior

Both builders produce the same IIFE shape. Pro only overrides the sections it needs to change. No code duplication.

### 2. Testable in isolation

Each section method can be unit-tested with a mock `RenderRequest`:

```ruby
builder = ReactOnRails::JsCodeBuilder.new
req = RenderRequest.new(component_name: "Foo", props: { a: 1 }, ...)
assert_includes builder.send(:props_section, req), '"a":1'
```

### 3. No regex-based dispatch

The RSC component name/props replacement still uses regex on the generated IIFE (this is a Node renderer requirement), but it's isolated in `rsc_payload_function` rather than affecting the overall code structure.

### 4. Eliminates `ServerRenderingJsCode` module

The `server_rendering_component_js_code` method with its `js_code_renderer` dispatch is replaced by `RenderRequest#to_js` calling the configured builder.

## Alternative Considered: JSON Protocol to Node Renderer

For the Node renderer path, we could skip JS code generation entirely and send a JSON payload:

```json
{
  "componentName": "MyComponent",
  "props": { "data": "value" },
  "railsContext": { ... },
  "stores": [
    { "name": "appStore", "props": { ... } }
  ],
  "renderMode": "html_streaming",
  "trace": false
}
```

The Node renderer would then call `ReactOnRails.serverRenderReactComponent(...)` itself. This would:

- Eliminate all JS string building for the Node path
- Make the protocol language-agnostic
- Enable the Node renderer to optimize the execution path

**However**, this is a larger change that requires modifying the Node renderer to understand render requests natively. It's recommended as a **Phase 2** improvement (see `05-node-renderer-protocol.md`).

## Migration Path

1. Create `JsCodeBuilder` with the same output as current `ServerRenderingJsCode.render`
2. Create `ReactOnRailsPro::JsCodeBuilder` with the same output as current Pro `render`
3. Wire `RenderRequest#to_js` to call the configured builder
4. Verify output matches character-for-character with existing generators
5. Remove `ServerRenderingJsCode` module and `js_code_renderer` dispatch
