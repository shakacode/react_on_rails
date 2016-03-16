# rubocop:disable Metrics/ModuleLength
# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var
require "react_on_rails/prerender_error"

module ReactOnRailsHelper
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
  #         let MyReactComponentApp = (props) => <MyReactComponent {...props}/>;
  #      or using ES5
  #         var MyReactComponentApp = function(props) { return <YourReactComponent {...props}/>; }
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
  #   trace: <true/false> set to true to print additional debugging information in the browser
  #          default is true for development, off otherwise
  #   replay_console: <true/false> Default is true. False will disable echoing server rendering
  #                   logs to browser. While this can make troubleshooting server rendering difficult,
  #                   so long as you have the default configuration of logging_on_server set to
  #                   true, you'll still see the errors on the server.
  #   raise_on_prerender_error: <true/false> Default to false. True will raise exception on server
  #      if the JS code throws
  # Any other options are passed to the content tag, including the id.
  def react_component(component_name, options = {}, other_options = nil)
    # Create the JavaScript and HTML to allow either client or server rendering of the
    # react_component.
    #
    # Create the JavaScript setup of the global to initialize the client rendering
    # (re-hydrate the data). This enables react rendered on the client to see that the
    # server has already rendered the HTML.
    # We use this react_component_index in case we have the same component multiple times on the page.

    options, props = parse_options_props(component_name, options, other_options)

    react_component_index = next_react_component_index
    react_component_name = component_name.camelize # Not sure if we should be doing this (JG)
    dom_id = if options[:id].nil?
               "#{component_name}-react-component-#{react_component_index}"
             else
               options[:id]
             end

    # Setup the page_loaded_js, which is the same regardless of prerendering or not!
    # The reason is that React is smart about not doing extra work if the server rendering did its job.

    props = {} if props.nil?

    data = {
      component_name: react_component_name,
      props: props,
      trace: trace(options),
      dom_id: dom_id
    }

    if options[:route].present?
      route = { route: options[:route] }
      data.merge!(route)
    end

    component_specification_tag =
      content_tag(:div,
                  "",
                  class: "js-react-on-rails-component",
                  style: ReactOnRails.configuration.skip_display_none ? nil : "display:none",
                  data: data)

    # Create the HTML rendering part
    result = server_rendered_react_component_html(options, props, react_component_name, dom_id)

    server_rendered_html = result["html"]
    console_script = result["consoleReplayScript"]

    content_tag_options = options.except(:generator_function, :prerender, :trace,
                                         :replay_console, :id, :react_component_name,
                                         :server_side, :raise_on_prerender_error)
    content_tag_options[:id] = dom_id

    rendered_output = content_tag(:div,
                                  server_rendered_html.html_safe,
                                  content_tag_options)

    # IMPORTANT: Ensure that we mark string as html_safe to avoid escaping.
    <<-HTML.html_safe
#{component_specification_tag}
    #{rendered_output}
    #{replay_console(options) ? console_script : ''}
    HTML
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
      render_redux_store_data(redux_store_data)
    end
  end

  # Place this view helper (no parameters) at the end of your shared layout. This tell
  # ReactOnRails where to client render the redux store hydration data. Since we're going
  # to be setting up the stores in the controllers, we need to know where on the view to put the
  # client side rendering of this hydration data, which is a hidden div with a matching class
  # that contains a data props.
  def redux_store_hydration_data
    return if @registered_stores_defer_render.blank?
    @registered_stores_defer_render.reduce("") do |accum, redux_store_data|
      accum << render_redux_store_data(redux_store_data)
    end.html_safe
  end

  def sanitized_props_string(props)
    props.is_a?(String) ? json_escape(props) : props.to_json
  end

  # Helper method to take javascript expression and returns the output from evaluating it.
  # If you have more than one line that needs to be executed, wrap it in an IIFE.
  # JS exceptions are caught and console messages are handled properly.
  def server_render_js(js_expression, options = {})
    wrapper_js = <<-JS
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

    result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)

    # IMPORTANT: To ensure that Rails doesn't auto-escape HTML tags, use the 'raw' method.
    html = result["html"]
    console_log_script = result["consoleLogScript"]
    raw("#{html}#{replay_console(options) ? console_log_script : ''}")
  rescue ExecJS::ProgramError => err
    # rubocop:disable Style/RaiseArgs
    raise ReactOnRails::PrerenderError.new(component_name: "N/A (server_render_js called)",
                                           err: err,
                                           js_code: wrapper_js)
    # rubocop:enable Style/RaiseArgs
  end

  private

  def render_redux_store_data(redux_store_data)
    content_tag(:div,
                "",
                class: "js-react-on-rails-store",
                style: ReactOnRails.configuration.skip_display_none ? nil : "display:none",
                data: redux_store_data)
  end

  def next_react_component_index
    @react_component_index ||= -1
    @react_component_index += 1
  end

  def props_string(props)
    props.is_a?(String) ? props : props.to_json
  end

  # Returns Array [0]: html, [1]: script to console log
  # NOTE, these are NOT html_safe!
  def server_rendered_react_component_html(options, props, react_component_name, dom_id)
    return { "html" => "", "consoleReplayScript" => "" } unless prerender(options)

    # On server `location` option is added (`location = request.fullpath`)
    # React Router needs this to match the current route

    # Make sure that we use up-to-date server-bundle
    ReactOnRails::ServerRenderingPool.reset_pool_if_server_bundle_was_modified

    # Since this code is not inserted on a web page, we don't need to escape props

    wrapper_js = <<-JS
(function() {
#{initialize_redux_stores}
  var props = #{props_string(props)};
  if (#{options[:route].present?}) {
    return ReactOnRails.serverRenderRelayComponents({
      name: '#{react_component_name}',
      domNodeId: '#{dom_id}',
      route: '#{options[:route]}',
      trace: #{trace(options)},
      location: '#{request.fullpath}'
    })
  } else {
    return ReactOnRails.serverRenderReactComponent({
      name: '#{react_component_name}',
      domNodeId: '#{dom_id}',
      props: props,
      trace: #{trace(options)},
      location: '#{request.fullpath}'
    });
  }
})()
    JS

    result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)

    if result["hasErrors"] && raise_on_prerender_error(options)
      # We caught this exception on our backtrace handler
      # rubocop:disable Style/RaiseArgs
      raise ReactOnRails::PrerenderError.new(component_name: react_component_name,
                                             # Sanitize as this might be browser logged
                                             props: sanitized_props_string(props),
                                             err: nil,
                                             js_code: wrapper_js,
                                             console_messages: result["consoleReplayScript"])
      # rubocop:enable Style/RaiseArgs
    end
    result
  rescue ExecJS::ProgramError => err
    # This error came from execJs
    # rubocop:disable Style/RaiseArgs
    raise ReactOnRails::PrerenderError.new(component_name: react_component_name,
                                           # Sanitize as this might be browser logged
                                           props: sanitized_props_string(props),
                                           err: err,
                                           js_code: wrapper_js)
    # rubocop:enable Style/RaiseArgs
  end

  def initialize_redux_stores
    return "" unless @registered_stores.present? || @registered_stores_defer_render.present?
    declarations = "var reduxProps, store, storeGenerator;\n"

    all_stores = (@registered_stores || []) + (@registered_stores_defer_render || [])

    result = all_stores.each_with_object(declarations) do |redux_store_data, memo|
      store_name = redux_store_data[:store_name]
      props = props_string(redux_store_data[:props])
      memo << <<-JS
reduxProps = #{props};
storeGenerator = ReactOnRails.getStoreGenerator('#{store_name}');
store = storeGenerator(reduxProps);
ReactOnRails.setStore('#{store_name}', store);
      JS
    end
    result
  end

  def raise_on_prerender_error(options)
    options.fetch(:raise_on_prerender_error) { ReactOnRails.configuration.raise_on_prerender_error }
  end

  def trace(options)
    options.fetch(:trace) { ReactOnRails.configuration.trace }
  end

  def prerender(options)
    options.fetch(:prerender) { ReactOnRails.configuration.prerender }
  end

  def replay_console(options)
    options.fetch(:replay_console) { ReactOnRails.configuration.replay_console }
  end

  def parse_options_props(component_name, options, other_options)
    other_options ||= {}
    if options.is_a?(Hash) && options.key?(:props)
      props = options[:props]
      if options.key?(:route)
        final_options = options.except([:props, :route])
      else
        final_options = options.except(:props)
      end
      final_options.merge!(other_options) if other_options.present?
    else
      # either no props specified or deprecated
      if other_options.present? || options.is_a?(String)
        deprecated_syntax = true
      else
        options_has_no_reserved_keys =
          %i(prerender trace replay_console raise_on_prerender_error).none? do |key|
            options.key?(key)
          end
        deprecated_syntax = options_has_no_reserved_keys
      end

      if deprecated_syntax
        puts "Deprecation: react_component now takes props as an explicity named parameter :props. "\
          " Props as the second arg will be removed in a future release. Called for "\
          "component_name: #{component_name}, controller: #{controller_name}, "\
          "action: #{action_name}."
        props = options
        final_options = other_options
      else
        options ||= {}
        final_options = options.merge(other_options)
      end
    end
    [final_options, props]
  end

  def use_hot_reloading?
    ENV["REACT_ON_RAILS_ENV"] == "HOT"
  end

  def send_tag_method(tag_method_name, args)
    asset_type = use_hot_reloading? ? :hot : :static
    assets = Array(args[asset_type])
    options = args.delete_if { |key, _value| %i(hot static).include?(key) }
    send(tag_method_name, *assets, options) unless assets.empty?
  end
end
