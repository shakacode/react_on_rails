# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var
require "react_on_rails/prerender_error"
require_relative "react_on_rails_helper/react_component/renderer"
require_relative "react_on_rails_helper/react_component/options"
require_relative "react_on_rails_helper/react_component/index"

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

  def react_component(component_name, options = {})
    index = next_react_component_index
    react_component_options = ReactComponent::Options.new(component_name,
                                                          index,
                                                          options)
    result = ReactComponent::Renderer.new(react_component_options).call
    prepend_render_rails_context(result)
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
    @registered_stores_defer_render.reduce("") do |accum, redux_store_data|
      accum << render_redux_store_data(redux_store_data)
    end.html_safe
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
    raw("#{html}#{replay_console_option(options[:replay_console_option]) ? console_log_script : ''}")
  rescue ExecJS::ProgramError => err
    # rubocop:disable Style/RaiseArgs
    raise ReactOnRails::PrerenderError.new(component_name: "N/A (server_render_js called)",
                                           err: err,
                                           js_code: wrapper_js)
    # rubocop:enable Style/RaiseArgs
  end

  private

  # prepend the rails_context if not yet applied
  def prepend_render_rails_context(render_value)
    return render_value if @rendered_rails_context

    data = {
      rails_context: rails_context(server_side: false)
    }

    @rendered_rails_context = true

    rails_context_content = content_tag(:div,
                                        "",
                                        id: "js-react-on-rails-context",
                                        style: ReactOnRails.configuration.skip_display_none ? nil : "display:none",
                                        data: data)
    "#{rails_context_content}\n#{render_value}".html_safe
  end

  def render_redux_store_data(redux_store_data)
    result = content_tag(:div,
                         "",
                         class: "js-react-on-rails-store",
                         style: ReactOnRails.configuration.skip_display_none ? nil : "display:none",
                         data: redux_store_data)
    prepend_render_rails_context(result)
  end

  def next_react_component_index
    @react_component_index ||= ReactComponent::Index.new
    @react_component_index.next
  end

  # This is the definitive list of the default values used for the rails_context, which is the
  # second parameter passed to both component and store generator functions.
  def rails_context(server_side:)
    @rails_context ||= begin
      uri = URI.parse(request.original_url)
      # uri = URI("http://foo.com:3000/posts?id=30&limit=5#time=1305298413")

      result = {
        # URL settings
        href: request.original_url,
        location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}" : ''}",
        scheme: uri.scheme, # http
        host: uri.host, # foo.com
        port: uri.port,
        pathname: uri.path, # /posts
        search: uri.query, # id=30&limit=5

        # Locale settings
        i18nLocale: I18n.locale,
        i18nDefaultLocale: I18n.default_locale,
        httpAcceptLanguage: request.env["HTTP_ACCEPT_LANGUAGE"]
      }

      if ReactOnRails.configuration.rendering_extension
        custom_context = ReactOnRails.configuration.rendering_extension.custom_context(self)
        result.merge!(custom_context) if custom_context
      end
      result
    end

    @rails_context.merge(serverSide: server_side)
  end

  def replay_console_option(val)
    val.nil? ? ReactOnRails.configuration.replay_console : val
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
