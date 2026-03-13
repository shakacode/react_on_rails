# frozen_string_literal: true

class PagesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ReactOnRailsPro::RSCPayloadRenderer
  include RscPostsPageOverRedisHelper
  include ReactOnRailsPro::AsyncRendering

  enable_async_react_rendering only: [:async_components_demo]

  XSS_PAYLOAD = { "<script>window.alert('xss1');</script>" => '<script>window.alert("xss2");</script>' }.freeze
  PROPS_NAME = "Mr. Server Side Rendering"
  APP_PROPS_SERVER_RENDER = {
    helloWorldData: {
      name: PROPS_NAME
    }.merge(XSS_PAYLOAD)
  }.freeze

  before_action do
    session[:something_useful] = "REALLY USEFUL"
  end

  before_action :apply_config_overrides, only: %i[
    error_scenarios_hub
    server_side_log_throw
    server_router
    ssr_shell_error
    ssr_async_error
    ssr_sync_error
    ssr_async_prop_error
    rsc_component_error
    non_existing_react_component
    non_existing_stream_react_component
    non_existing_rsc_payload
    stream_error_demo
    stream_shell_error_demo
  ]
  before_action :data

  before_action :initialize_shared_store, only: %i[client_side_hello_world_shared_store_controller
                                                   server_side_hello_world_shared_store_controller]

  # Used for testing streamed html pages
  # Capybara doesn't support streaming, so we need to navigate to an empty page first
  # and then make an XHR request to the desired page
  # We need to navigate to an empty page first to avoid CORS issues and to update the page host
  def empty
    render plain: ""
  end

  def cached_react_helmet
    render "/pages/pro/cached_react_helmet"
  end

  def error_scenarios_hub
    render "/pages/error_scenarios_hub"
  end

  def reset_error_configs
    ReactOnRails.configuration.raise_on_prerender_error = Rails.env.development?
    ReactOnRailsPro.configuration.throw_js_errors = false
    ReactOnRailsPro.configuration.raise_non_shell_server_rendering_errors = false
    redirect_to error_scenarios_hub_path
  end

  def ssr_shell_error
    stream_view_containing_react_components(template: "/pages/ssr_shell_error")
  end

  def ssr_async_error
    stream_view_containing_react_components(template: "/pages/ssr_async_error")
  end

  def ssr_sync_error
    stream_view_containing_react_components(template: "/pages/ssr_sync_error")
  end

  def ssr_async_prop_error
    stream_view_containing_react_components(template: "/pages/ssr_async_prop_error")
  end

  def rsc_component_error
    stream_view_containing_react_components(template: "/pages/rsc_component_error")
  end

  def non_existing_react_component
    render "/pages/non_existing_react_component"
  end

  def non_existing_stream_react_component
    stream_view_containing_react_components(template: "/pages/non_existing_stream_react_component")
  end

  def non_existing_rsc_payload
    stream_view_containing_react_components(template: "/pages/non_existing_rsc_payload")
  end

  def stream_error_demo
    stream_view_containing_react_components(template: "/pages/stream_error_demo")
  end

  def stream_shell_error_demo
    stream_view_containing_react_components(template: "/pages/stream_shell_error_demo")
  end

  def stream_async_components
    stream_view_containing_react_components(template: "/pages/stream_async_components")
  end

  def stream_async_components_for_testing
    stream_view_containing_react_components(template: "/pages/stream_async_components_for_testing")
  end

  def cached_stream_async_components_for_testing
    stream_view_containing_react_components(template: "/pages/cached_stream_async_components_for_testing")
  end

  def rsc_echo_props
    stream_view_containing_react_components(template: "/pages/rsc_echo_props")
  end

  def rsc_posts_page_over_http
    stream_view_containing_react_components(template: "/pages/rsc_posts_page_over_http")
  end

  def rsc_posts_page_over_redis
    @request_id = SecureRandom.uuid

    redis_thread = Thread.new do
      redis = ::Redis.new
      write_posts_and_comments_to_redis(redis)
    rescue StandardError => e
      Rails.logger.error "Error writing posts and comments to Redis: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    stream_view_containing_react_components(template: "/pages/rsc_posts_page_over_redis")

    return if redis_thread.join(10)

    Rails.logger.error "Redis thread timed out"
    raise "Redis thread timed out"
  end

  def redis_receiver
    @request_id = SecureRandom.uuid

    redis_thread = Thread.new do
      redis = ::Redis.new
      5.times do |index|
        sleep 1
        redis.xadd("stream:#{@request_id}", { ":Item#{index}" => "Value of Item#{index + 1}".to_json })
      end
    rescue StandardError => e
      Rails.logger.error "Error writing Items to Redis: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    ensure
      begin
        redis&.close
      rescue StandardError => e
        Rails.logger.warn "Failed to close Redis: #{e.message}"
      end
    end

    stream_view_containing_react_components(template: "/pages/redis_receiver")

    return if redis_thread.join(10)

    Rails.logger.error "Redis thread timed out"
    raise "Redis thread timed out"
  end

  def redis_receiver_for_testing
    @request_id = params[:request_id]
    raise "request_id is required at the url" if @request_id.blank?

    stream_view_containing_react_components(template: "/pages/redis_receiver")
  end

  def async_on_server_sync_on_client
    @render_on_server = true
    stream_view_containing_react_components(template: "/pages/async_on_server_sync_on_client")
  end

  def async_on_server_sync_on_client_client_render
    @render_on_server = false
    render "/pages/async_on_server_sync_on_client"
  end

  def server_router
    stream_view_containing_react_components(template: "/pages/server_router")
  end

  def server_side_hello_world_hooks
    stream_view_containing_react_components(template: "/pages/server_side_hello_world_hooks")
  end

  def posts_page
    posts = fetch_posts.as_json
    posts.each do |post|
      post_comments = fetch_post_comments(post, []).as_json
      post_comments.each do |comment|
        comment["user"] = fetch_comment_user(comment).as_json
      end
      post["comments"] = post_comments
    end

    @posts = posts
    render "/pages/posts_page"
  end

  def loadable_component
    render "/pages/pro/loadable_component"
  end

  def cached_redux_component
    render "/pages/pro/cached_redux_component"
  end

  def server_render_with_timeout
    render "/pages/pro/server_render_with_timeout"
  end

  def apollo_graphql
    render "/pages/pro/apollo_graphql"
  end

  def lazy_apollo_graphql
    render "/pages/pro/lazy_apollo_graphql"
  end

  def console_logs_in_async_server
    render "/pages/pro/console_logs_in_async_server"
  end

  # Demo page showing 10 async components rendering concurrently
  # Each component delays 1 second - sequential would take ~10s, concurrent takes ~1s
  def async_components_demo
    render "/pages/pro/async_components_demo"
  end

  # See files in spec/dummy/app/views/pages

  helper_method :calc_slow_app_props_server_render

  private

  def calc_slow_app_props_server_render
    msg = <<-MSG.strip_heredoc
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      calling slow calc_slow_app_props_server_render
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    MSG
    Rails.logger.info msg
    render_to_string(template: "/pages/pro/serialize_props",
                     locals: { name: PROPS_NAME }, formats: :json)
  end

  def apply_config_overrides
    # NOTE: This mutates global React on Rails config singletons and is not thread-safe.
    # It is intended only for manual debugging in the dummy app.
    bool = ActiveModel::Type::Boolean.new

    if params[:raise_on_prerender_error].present?
      ReactOnRails.configuration.raise_on_prerender_error =
        bool.cast(params[:raise_on_prerender_error])
    end
    if params[:throw_js_errors].present?
      ReactOnRailsPro.configuration.throw_js_errors = bool.cast(params[:throw_js_errors])
    end
    return unless params[:raise_non_shell_server_rendering_errors].present?

    ReactOnRailsPro.configuration.raise_non_shell_server_rendering_errors =
      bool.cast(params[:raise_non_shell_server_rendering_errors])
  end

  def initialize_shared_store
    redux_store("SharedReduxStore", props: @app_props_server_render)
  end

  def data
    # This is the props used by the React component.
    @app_props_server_render = APP_PROPS_SERVER_RENDER

    @app_props_hello = {
      helloWorldData: {
        name: "Mrs. Client Side Rendering"
      }.merge(XSS_PAYLOAD)
    }

    @app_props_hello_again = {
      helloWorldData: {
        name: "Mrs. Client Side Hello Again"
      }.merge(XSS_PAYLOAD)
    }
  end
end
