# frozen_string_literal: true

module ReactOnRailsPro
  # Pro JS code builder that extends the base JsCodeBuilder with RSC support,
  # pre-hooks, and Node renderer-specific options.
  #
  # Part of the strategy pattern refactoring (see issue #2905).
  # Currently additive — not yet wired into the main rendering path.
  class JsCodeBuilder < ReactOnRails::JsCodeBuilder
    protected

    def build_sections(render_request)
      [
        rails_context_section(render_request),
        rsc_params_section(render_request),
        rsc_payload_function_section(render_request),
        pre_hook_section(render_request),
        store_initialization_section(render_request),
        props_section(render_request),
        render_call_section(render_request)
      ]
    end

    def rsc_params_section(render_request)
      return nil unless rsc_streaming?(render_request)

      config = ReactOnRailsPro.configuration
      react_client_manifest_file = config.react_client_manifest_file
      react_server_client_manifest_file = config.react_server_client_manifest_file

      <<~JS.chomp
        railsContext.reactClientManifestFileName = #{react_client_manifest_file.to_json};
        railsContext.reactServerClientManifestFileName = #{react_server_client_manifest_file.to_json};
      JS
    end

    def rsc_payload_function_section(render_request)
      return nil unless rsc_streaming?(render_request)

      if render_request.rsc_payload_streaming?
        <<~JS.chomp
          if (typeof generateRSCPayload !== 'function') {
            globalThis.generateRSCPayload = function generateRSCPayload() {
              throw new Error('The rendering request is already running on the RSC bundle. Please ensure that generateRSCPayload is only called from any React Server Component.')
            }
          }
        JS
      else
        <<~JS.chomp
          railsContext.serverSideRSCPayloadParameters = {
            renderingRequest,
            rscBundleHash: #{ReactOnRailsPro::Utils.rsc_bundle_hash.to_json},
          }
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
    end

    def pre_hook_section(_render_request)
      pre_hook = ReactOnRailsPro.configuration.ssr_pre_hook_js
      pre_hook.presence
    end

    def props_section(render_request)
      "var usedProps = typeof props === 'undefined' ? #{render_request.props_string} : props;"
    end

    def render_call_section(render_request)
      render_function_name = resolve_render_function_name(render_request)

      <<~JS.chomp
        return ReactOnRails[#{render_function_name}]({
          name: componentName,
          domNodeId: #{render_request.dom_id.to_json},
          props: usedProps,
          trace: #{render_request.render_options.trace},
          railsContext: railsContext,
          throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
          renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises},
        });
      JS
    end

    def wrap_in_iife(body, render_request)
      "(function(componentName = #{render_request.component_name.to_json}, props = undefined) {\n#{body}\n})()"
    end

    private

    def rsc_streaming?(render_request)
      ReactOnRailsPro.configuration.enable_rsc_support && render_request.streaming?
    end

    def resolve_render_function_name(render_request)
      if rsc_streaming?(render_request)
        "ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent'"
      else
        "'serverRenderReactComponent'"
      end
    end
  end
end
