# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var
require "react_on_rails/prerender_error"
require "addressable/uri"
require "react_on_rails/utils"
require "react_on_rails/json_output"
require "active_support/concern"

module ReactOnRails
  module Helper
    include ReactOnRails::Utils::Required

    COMPONENT_HTML_KEY = "componentHtml".freeze

    # The env_javascript_include_tag and env_stylesheet_link_tag support the usage of a webpack
    # dev server for providing the JS and CSS assets during development mode. See
    # https://github.com/shakacode/react-webpack-rails-tutorial/ for a working example.
    #
    # The key options are `static` and `hot` which specify what you want for static vs. hot. Both of
    # these params are optional, and support either a single value, or an array.
    #
    # static vs. hot is picked based on whether
    # ENV["REACT_ON_RAILS_ENV"] == "HOT"
    #
    #   <%= env_stylesheet_link_tag(static: 'application_static',
    #                               hot: 'application_non_webpack',
    #                               media: 'all',
    #                               'data-turbolinks-track' => "reload")  %>
    #
    #   <!-- These do not use turbolinks, so no data-turbolinks-track -->
    #   <!-- This is to load the hot assets. -->
    #   <%= env_javascript_include_tag(hot: ['http://localhost:3500/vendor-bundle.js',
    #                                        'http://localhost:3500/app-bundle.js']) %>
    #
    #   <!-- These do use turbolinks -->
    #   <%= env_javascript_include_tag(static: 'application_static',
    #                                  hot: 'application_non_webpack',
    #                                  'data-turbolinks-track' => "reload") %>
    #
    # NOTE: for Turbolinks 2.x, use 'data-turbolinks-track' => true
    # See application.html.erb for usage example
    # https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app%2Fviews%2Flayouts%2Fapplication.html.erb
    def env_javascript_include_tag(args = {})
      send_tag_method(:javascript_include_tag, args)
    end

    # Helper to set CSS assets depending on if we want static or "hot", which means from the
    # Webpack dev server.
    #
    # In this example, application_non_webpack is simply a CSS asset pipeline file which includes
    # styles not placed in the webpack build.
    #
    # We don't need styles from the webpack build, as those will come via the JavaScript include
    # tags.
    #
    # The key options are `static` and `hot` which specify what you want for static vs. hot. Both of
    # these params are optional, and support either a single value, or an array.
    #
    #   <%= env_stylesheet_link_tag(static: 'application_static',
    #                               hot: 'application_non_webpack',
    #                               media: 'all',
    #                               'data-turbolinks-track' => true)  %>
    #
    def env_stylesheet_link_tag(args = {})
      send_tag_method(:stylesheet_link_tag, args)
    end

    # react_component_name: can be a React component, created using a ES6 class, or
    #   React.createClass, or a
    #    `generator function` that returns a React component
    #      using ES6
    #         let MyReactComponentApp = (props, railsContext) => <MyReactComponent {...props}/>;
    #      or using ES5
    #         var MyReactComponentApp = function(props, railsContext) { return <YourReactComponent {...props}/>; }
    #   Exposing the react_component_name is necessary to both a plain ReactComponent as well as
    #     a generator:
    #   See README.md for how to "register" your react components.
    #   See spec/dummy/client/app/startup/serverRegistration.jsx and
    #     spec/dummy/client/app/startup/ClientRegistration.jsx for examples of this
    #
    # options:
    #   props: Ruby Hash or JSON string which contains the properties to pass to the react object. Do
    #      not pass any props if you are separately initializing the store by the `redux_store` helper.
    #   prerender: <true/false> set to false when debugging!
    #   id: You can optionally set the id, or else a unique one is automatically generated.
    #   html_options: You can set other html attributes that will go on this component
    #   trace: <true/false> set to true to print additional debugging information in the browser
    #          default is true for development, off otherwise
    #   replay_console: <true/false> Default is true. False will disable echoing server rendering
    #                   logs to browser. While this can make troubleshooting server rendering difficult,
    #                   so long as you have the default configuration of logging_on_server set to
    #                   true, you'll still see the errors on the server.
    #   raise_on_prerender_error: <true/false> Default to false. True will raise exception on server
    #      if the JS code throws
    # Any other options are passed to the content tag, including the id.
    def react_component(component_name, options = {})
      internal_result = internal_react_component(component_name, options)
      server_rendered_html = internal_result[:result]["html"]
      console_script = internal_result[:result]["consoleReplayScript"]

      if server_rendered_html.is_a?(String)
        build_react_component_result_for_server_rendered_string(
          server_rendered_html: server_rendered_html,
          component_specification_tag: internal_result[:tag],
          console_script: console_script,
          render_options: internal_result[:render_options]
        )
      elsif server_rendered_html.is_a?(Hash)
        msg = <<-MSG.strip_heredoc
        Use react_component_hash (not react_component) to return a Hash to your ruby view code. See
        https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/client/app/startup/ReactHelmetServerApp.jsx
        for an example of the necessary javascript configuration."
        MSG
        raise ReactOnRails::Error, msg

      else
        msg = <<-MSG.strip_heredoc
        ReactOnRails: server_rendered_html is expected to be a String for #{component_name}. If you're
        trying to use a generator function to return a Hash to your ruby view code, then use
        react_component_hash instead of react_component and see
        https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/client/app/startup/ReactHelmetServerApp.jsx
        for an example of the JavaScript code."
        MSG
        raise ReactOnRails::Error, msg
      end
    end

    # react_component_hash is used to return multiple HTML strings for server rendering, such as for
    # adding meta-tags to a page.
    # It is exactly like react_component except for the following:
    # 1. prerender: true is automatically added, as this method doesn't make sense for client only
    #    rendering.
    # 2. Your JavaScript for server rendering must return an Object for the key server_rendered_html.
    # 3. Your view code must expect an object and not a string.
    #
    # Here is an example of the view code:
    #    <% react_helmet_app = react_component_hash("ReactHelmetApp", prerender: true,
    #                                               props: { helloWorldData: { name: "Mr. Server Side Rendering"}},
    #                                               id: "react-helmet-0", trace: true) %>
    #    <% content_for :title do %>
    #      <%= react_helmet_app['title'] %>
    #    <% end %>
    #    <%= react_helmet_app["componentHtml"] %>
    #
    def react_component_hash(component_name, options = {})
      options[:prerender] = true
      internal_result = internal_react_component(component_name, options)
      server_rendered_html = internal_result[:result]["html"]
      console_script = internal_result[:result]["consoleReplayScript"]

      if server_rendered_html.is_a?(String) && internal_result[:result]["hasErrors"]
        server_rendered_html = { COMPONENT_HTML_KEY => internal_result[:result]["html"] }
      end

      if server_rendered_html.is_a?(Hash)
        build_react_component_result_for_server_rendered_hash(
          server_rendered_html: server_rendered_html,
          component_specification_tag: internal_result[:tag],
          console_script: console_script,
          render_options: internal_result[:render_options]
        )
      else
        msg = <<-MSG.strip_heredoc
          Generator function used by react_component_hash for #{component_name} is expected to return
          an Object. See https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/client/app/startup/ReactHelmetServerApp.jsx
          for an example of the JavaScript code."
        MSG
        raise ReactOnRails::Error, msg
      end
    end

    # Separate initialization of store from react_component allows multiple react_component calls to
    # use the same Redux store.
    #
    # store_name: name of the store, corresponding to your call to ReactOnRails.registerStores in your
    #             JavaScript code.
    # props: Ruby Hash or JSON string which contains the properties to pass to the redux store.
    # Options
    #    defer: false -- pass as true if you wish to render this below your component.
    def redux_store(store_name, props: {}, defer: false)
      redux_store_data = { store_name: store_name,
                           props: props }
      if defer
        @registered_stores_defer_render ||= []
        @registered_stores_defer_render << redux_store_data
        "YOU SHOULD NOT SEE THIS ON YOUR VIEW -- Uses as a code block, like <% redux_store %> "\
        "and not <%= redux store %>"
      else
        @registered_stores ||= []
        @registered_stores << redux_store_data
        result = render_redux_store_data(redux_store_data)
        prepend_render_rails_context(result)
      end
    end

    # Place this view helper (no parameters) at the end of your shared layout. This tell
    # ReactOnRails where to client render the redux store hydration data. Since we're going
    # to be setting up the stores in the controllers, we need to know where on the view to put the
    # client side rendering of this hydration data, which is a hidden div with a matching class
    # that contains a data props.
    def redux_store_hydration_data
      return if @registered_stores_defer_render.blank?
      @registered_stores_defer_render.reduce("".dup) do |accum, redux_store_data|
        accum << render_redux_store_data(redux_store_data)
      end.html_safe
    end

    def sanitized_props_string(props)
      ReactOnRails::JsonOutput.escape(props.is_a?(String) ? props : props.to_json)
    end

    # Helper method to take javascript expression and returns the output from evaluating it.
    # If you have more than one line that needs to be executed, wrap it in an IIFE.
    # JS exceptions are caught and console messages are handled properly.
    # Options include:{ prerender:, trace:, raise_on_prerender_error: }
    def server_render_js(js_expression, options = {})
      render_options = ReactOnRails::ReactComponent::RenderOptions
                       .new(react_component_name: "generic-js", options: options)

      js_code = <<-JS.strip_heredoc
      (function() {
        var htmlResult = '';
        var consoleReplayScript = '';
        var hasErrors = false;

        try {
          htmlResult =
            (function() {
              return #{js_expression};
            })();
        } catch(e) {
          htmlResult = ReactOnRails.handleError({e: e, name: null,
            jsCode: '#{escape_javascript(js_expression)}', serverSide: true});
          hasErrors = true;
        }

        consoleReplayScript = ReactOnRails.buildConsoleReplay();

        return JSON.stringify({
            html: htmlResult,
            consoleReplayScript: consoleReplayScript,
            hasErrors: hasErrors
        });

      })()
      JS

      result = ReactOnRails::ServerRenderingPool
               .server_render_js_with_console_logging(js_code, render_options)

      html = result["html"]
      console_log_script = result["consoleLogScript"]
      raw("#{html}#{render_options.replay_console ? console_log_script : ''}")
    rescue ExecJS::ProgramError => err
      raise ReactOnRails::PrerenderError, component_name: "N/A (server_render_js called)",
                                          err: err,
                                          js_code: js_code
    end

    def json_safe_and_pretty(hash_or_string)
      return "{}" if hash_or_string.nil?
      unless hash_or_string.class.in?([Hash, String])
        raise ReactOnRails::Error, "#{__method__} only accepts String or Hash as argument "\
            "(#{hash_or_string.class} given)."
      end

      json_value = hash_or_string.is_a?(String) ? hash_or_string : hash_or_string.to_json

      ReactOnRails::JsonOutput.escape(json_value)
    end

    private

    def build_react_component_result_for_server_rendered_string(
      server_rendered_html: required("server_rendered_html"),
      component_specification_tag: required("component_specification_tag"),
      console_script: required("console_script"),
      render_options: required("render_options")
    )
      content_tag_options = render_options.html_options
      content_tag_options[:id] = render_options.dom_id

      rendered_output = content_tag(:div,
                                    server_rendered_html.html_safe,
                                    content_tag_options)

      result_console_script = render_options.replay_console ? console_script : ""
      result = compose_react_component_html_with_spec_and_console(
        component_specification_tag, rendered_output, result_console_script
      )

      prepend_render_rails_context(result)
    end

    def build_react_component_result_for_server_rendered_hash(
      server_rendered_html: required("server_rendered_html"),
      component_specification_tag: required("component_specification_tag"),
      console_script: required("console_script"),
      render_options: required("render_options")
    )
      content_tag_options = render_options.html_options
      content_tag_options[:id] = render_options.dom_id

      unless server_rendered_html[COMPONENT_HTML_KEY]
        raise ReactOnRails::Error, "server_rendered_html hash expected to contain \"#{COMPONENT_HTML_KEY}\" key."
      end

      rendered_output = content_tag(:div,
                                    server_rendered_html[COMPONENT_HTML_KEY].html_safe,
                                    content_tag_options)

      result_console_script = render_options.replay_console ? console_script : ""
      result = compose_react_component_html_with_spec_and_console(
        component_specification_tag, rendered_output, result_console_script
      )

      # Other HTML strings need to be marked as html_safe too:
      server_rendered_hash_except_component = server_rendered_html.except(COMPONENT_HTML_KEY)
      server_rendered_hash_except_component.each do |key, html_string|
        server_rendered_hash_except_component[key] = html_string.html_safe
      end

      result_with_rails_context = prepend_render_rails_context(result)
      { COMPONENT_HTML_KEY => result_with_rails_context }.merge(
        server_rendered_hash_except_component
      )
    end

    def compose_react_component_html_with_spec_and_console(component_specification_tag, rendered_output, console_script)
      # IMPORTANT: Ensure that we mark string as html_safe to avoid escaping.
      # rubocop:disable Layout/IndentHeredoc
      <<-HTML.html_safe
#{rendered_output}
      #{component_specification_tag}
      #{console_script}
      HTML
      # rubocop:enable Layout/IndentHeredoc
    end

    # prepend the rails_context if not yet applied
    def prepend_render_rails_context(render_value)
      return render_value if @rendered_rails_context

      data = rails_context(server_side: false)

      @rendered_rails_context = true

      rails_context_content = content_tag(:script,
                                          json_safe_and_pretty(data).html_safe,
                                          type: "application/json",
                                          id: "js-react-on-rails-context")

      "#{rails_context_content}\n#{render_value}".html_safe
    end

    def internal_react_component(react_component_name, options = {})
      # Create the JavaScript and HTML to allow either client or server rendering of the
      # react_component.
      #
      # Create the JavaScript setup of the global to initialize the client rendering
      # (re-hydrate the data). This enables react rendered on the client to see that the
      # server has already rendered the HTML.

      render_options = ReactOnRails::ReactComponent::RenderOptions.new(react_component_name: react_component_name,
                                                                       options: options)

      # Setup the page_loaded_js, which is the same regardless of prerendering or not!
      # The reason is that React is smart about not doing extra work if the server rendering did its job.
      component_specification_tag = content_tag(:script,
                                                json_safe_and_pretty(render_options.props).html_safe,
                                                type: "application/json",
                                                class: "js-react-on-rails-component",
                                                "data-component-name" => render_options.react_component_name,
                                                "data-trace" => (render_options.trace ? true : nil),
                                                "data-dom-id" => render_options.dom_id)

      # Create the HTML rendering part
      result = server_rendered_react_component(render_options)

      {
        render_options: render_options,
        tag: component_specification_tag,
        result: result
      }
    end

    def render_redux_store_data(redux_store_data)
      result = content_tag(:script,
                           json_safe_and_pretty(redux_store_data[:props]).html_safe,
                           type: "application/json",
                           "data-js-react-on-rails-store" => redux_store_data[:store_name].html_safe)

      prepend_render_rails_context(result)
    end

    def props_string(props)
      props.is_a?(String) ? props : props.to_json
    end

    # Returns object with values that are NOT html_safe!
    def server_rendered_react_component(render_options)
      return { "html" => "", "consoleReplayScript" => "" } unless render_options.prerender

      react_component_name = render_options.react_component_name
      props = render_options.props

      # On server `location` option is added (`location = request.fullpath`)
      # React Router needs this to match the current route

      # Make sure that we use up-to-date bundle file used for server rendering, which is defined
      # by config file value for config.server_bundle_js_file
      ReactOnRails::ServerRenderingPool.reset_pool_if_server_bundle_was_modified

      # Since this code is not inserted on a web page, we don't need to escape props
      #
      # However, as JSON (returned from `props_string(props)`) isn't JavaScript,
      # but we want treat it as such, we need to compensate for the difference.
      #
      # \u2028 and \u2029 are valid characters in strings in JSON, but are treated
      # as newline separators in JavaScript. As no newlines are allowed in
      # strings in JavaScript, this causes an exception.
      #
      # We fix this by replacing these unicode characters with their escaped versions.
      # This should be safe, as the only place they can appear is in strings anyway.
      #
      # Read more here: http://timelessrepo.com/json-isnt-a-javascript-subset

      # rubocop:disable Layout/IndentHeredoc
      js_code = <<-JS
(function() {
  var railsContext = #{rails_context(server_side: true).to_json};
#{initialize_redux_stores}
  var props = #{props_string(props).gsub("\u2028", '\u2028').gsub("\u2029", '\u2029')};
  return ReactOnRails.serverRenderReactComponent({
    name: '#{react_component_name}',
    domNodeId: '#{render_options.dom_id}',
    props: props,
    trace: #{render_options.trace},
    railsContext: railsContext
  });
})()
      JS
      # rubocop:enable Layout/IndentHeredoc

      begin
        result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(js_code, render_options)
      rescue StandardError => err
        # This error came from the renderer
        raise ReactOnRails::PrerenderError, component_name: react_component_name,
                                            # Sanitize as this might be browser logged
                                            props: sanitized_props_string(props),
                                            err: err,
                                            js_code: js_code
      end

      if result["hasErrors"] && render_options.raise_on_prerender_error
        # We caught this exception on our backtrace handler
        raise ReactOnRails::PrerenderError, component_name: react_component_name,
                                            # Sanitize as this might be browser logged
                                            props: sanitized_props_string(props),
                                            err: nil,
                                            js_code: js_code,
                                            console_messages: result["consoleReplayScript"]

      end
      result
    end

    def initialize_redux_stores
      return "" unless @registered_stores.present? || @registered_stores_defer_render.present?
      declarations = "var reduxProps, store, storeGenerator;\n".dup
      all_stores = (@registered_stores || []) + (@registered_stores_defer_render || [])

      result = <<-JS.dup
      ReactOnRails.clearHydratedStores();
      JS

      result << all_stores.each_with_object(declarations) do |redux_store_data, memo|
        store_name = redux_store_data[:store_name]
        props = props_string(redux_store_data[:props])
        memo << <<-JS.strip_heredoc
        reduxProps = #{props};
        storeGenerator = ReactOnRails.getStoreGenerator('#{store_name}');
        store = storeGenerator(reduxProps, railsContext);
        ReactOnRails.setStore('#{store_name}', store);
        JS
      end
      result
    end

    # This is the definitive list of the default values used for the rails_context, which is the
    # second parameter passed to both component and store generator functions.
    # rubocop:disable Metrics/AbcSize
    def rails_context(server_side: required("server_side"))
      @rails_context ||= begin
        result = {
          railsEnv: Rails.env,
          inMailer: in_mailer?,
          # Locale settings
          i18nLocale: I18n.locale,
          i18nDefaultLocale: I18n.default_locale,
          rorVersion: ReactOnRails::VERSION,
          rorPro: ReactOnRails::Utils.react_on_rails_pro?
        }
        if defined?(request) && request.present?
          # Check for encoding of the request's original_url and try to force-encoding the
          # URLs as UTF-8. This situation can occur in browsers that do not encode the
          # entire URL as UTF-8 already, mostly on the Windows platform (IE11 and lower).
          original_url_normalized = request.original_url
          if original_url_normalized.encoding.to_s == "ASCII-8BIT"
            original_url_normalized = original_url_normalized.force_encoding("ISO-8859-1").encode("UTF-8")
          end

          # Using Addressable instead of standard URI to better deal with
          # non-ASCII characters (see https://github.com/shakacode/react_on_rails/pull/405)
          uri = Addressable::URI.parse(original_url_normalized)
          # uri = Addressable::URI.parse("http://foo.com:3000/posts?id=30&limit=5#time=1305298413")

          result.merge!(
            # URL settings
            href: uri.to_s,
            location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}" : ''}",
            scheme: uri.scheme, # http
            host: uri.host, # foo.com
            port: uri.port,
            pathname: uri.path, # /posts
            search: uri.query, # id=30&limit=5
            httpAcceptLanguage: request.env["HTTP_ACCEPT_LANGUAGE"]
          )
        end
        if ReactOnRails.configuration.rendering_extension
          custom_context = ReactOnRails.configuration.rendering_extension.custom_context(self)
          result.merge!(custom_context) if custom_context
        end
        result
      end

      @rails_context.merge(serverSide: server_side)
    end

    # rubocop:enable Metrics/AbcSize

    def replay_console_option(val)
      val.nil? ? ReactOnRails.configuration.replay_console : val
    end

    def use_hot_reloading?
      ENV["REACT_ON_RAILS_ENV"] == "HOT"
    end

    def send_tag_method(tag_method_name, args)
      asset_type = use_hot_reloading? ? :hot : :static
      assets = Array(args[asset_type])
      options = args.delete_if { |key, _value| %i[hot static].include?(key) }
      send(tag_method_name, *assets, options) unless assets.empty?
    end

    def in_mailer?
      return false unless defined?(controller)
      return false unless defined?(ActionMailer::Base)

      controller.is_a?(ActionMailer::Base)
    end
  end
end
# rubocop:enable Metrics/ModuleLength
