# frozen_string_literal: true

module ReactOnRailsPro
  module ServerRenderingJsCode
    class << self
      def ssr_pre_hook_js
        ReactOnRailsPro.configuration.ssr_pre_hook_js || ""
      end

      # Generates the JavaScript function used for React Server Components payload generation
      # Returns the JavaScript code that defines the generateRSCPayload function.
      # It also adds necessary information to the railsContext to generate the RSC payload for any component in the app.
      # @return [String] JavaScript code for RSC payload generation
      def generate_rsc_payload_js_function(render_options)
        return "" unless ReactOnRailsPro.configuration.enable_rsc_support && render_options.streaming?

        if render_options.rsc_payload_streaming?
          # When already on RSC bundle, we prevent further RSC payload generation
          # by throwing an error if generateRSCPayload is called
          return <<-JS
            if (typeof generateRSCPayload !== 'function') {
              globalThis.generateRSCPayload = function generateRSCPayload() {
                throw new Error('The rendering request is already running on the RSC bundle. Please ensure that generateRSCPayload is only called from any React Server Component.')
              }
            }
          JS
        end

        # To minimize the size of the HTTP request body sent to the node renderer,
        # we reuse the existing rendering request string within the generateRSCPayload function.
        # This approach allows us to simply replace the component name and props,
        # rather than rewriting the entire rendering request.
        # This regex finds the empty function call pattern `()` and replaces it with the component and props
        <<-JS
        railsContext.serverSideRSCPayloadParameters = {
          renderingRequest,
          rscBundleHash: '#{ReactOnRailsPro::Utils.rsc_bundle_hash}',
        }
        if (typeof generateRSCPayload !== 'function') {
          globalThis.generateRSCPayload = function generateRSCPayload(componentName, props, railsContext) {
            const { renderingRequest, rscBundleHash } = railsContext.serverSideRSCPayloadParameters;
            const propsString = JSON.stringify(props);
            const newRenderingRequest = renderingRequest.replace(/\\(\\s*\\)\\s*$/, function() { return `(${JSON.stringify(componentName)}, ${propsString})`; });
            return runOnOtherBundle(rscBundleHash, newRenderingRequest);
          }
        }
        JS
      end

      # Main rendering function that generates JavaScript code for server-side rendering
      # @param props_string [String] JSON string of props to pass to the React component
      # @param rails_context [String] JSON string of Rails context data
      # @param redux_stores [String] JavaScript code for Redux stores initialization
      # @param react_component_name [String] Name of the React component to render
      # @param render_options [Object] Options that control the rendering behavior
      # @return [String] JavaScript code that will render the React component on the server
      def render(props_string, rails_context, redux_stores, react_component_name, render_options)
        render_function_name =
          if ReactOnRailsPro.configuration.enable_rsc_support && render_options.streaming?
            # Select appropriate function based on whether the rendering request is running on server or rsc bundle
            # As the same rendering request is used to generate the rsc payload and SSR the component.
            "ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent'"
          else
            "'serverRenderReactComponent'"
          end
        rsc_params = if ReactOnRailsPro.configuration.enable_rsc_support && render_options.streaming?
                       config = ReactOnRailsPro.configuration
                       react_client_manifest_file = config.react_client_manifest_file
                       react_server_client_manifest_file = config.react_server_client_manifest_file
                       <<-JS
                          railsContext.reactClientManifestFileName = '#{react_client_manifest_file}';
                          railsContext.reactServerClientManifestFileName = '#{react_server_client_manifest_file}';
                       JS
                     else
                       ""
                     end

        # This function is called with specific componentName and props when generateRSCPayload is invoked
        # In that case, it replaces the empty () with ('componentName', props) in the rendering request
        <<-JS
        (function(componentName = '#{react_component_name}', props = undefined) {
          var railsContext = #{rails_context};
          #{rsc_params}
          #{generate_rsc_payload_js_function(render_options)}
          #{ssr_pre_hook_js}
          #{redux_stores}
          var usedProps = typeof props === 'undefined' ? #{props_string} : props;
          return ReactOnRails[#{render_function_name}]({
            name: componentName,
            domNodeId: '#{render_options.dom_id}',
            props: usedProps,
            trace: #{render_options.trace},
            railsContext: railsContext,
            throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
            renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises},
          });
        })()
        JS
      end
    end
  end
end
