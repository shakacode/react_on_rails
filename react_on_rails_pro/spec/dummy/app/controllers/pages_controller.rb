# frozen_string_literal: true

class PagesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ReactOnRailsPro::RSCPayloadRenderer
  include RscPostsPageOverRedisHelper
  include ReactOnRailsPro::AsyncRendering

  enable_async_react_rendering only: [:async_components_demo]

  LEAK_REPRO_ITEM_COUNT = ENV.fetch("LEAK_REPRO_ITEM_COUNT", "500").to_i

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

  around_action :with_config_overrides, only: %i[
    ssr_shell_error ssr_async_error ssr_sync_error ssr_async_prop_error
    rsc_component_error non_existing_react_component
    non_existing_stream_react_component non_existing_rsc_payload
    stream_error_demo stream_shell_error_demo
    server_side_log_throw server_router
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
    ensure
      begin
        redis&.close
      rescue StandardError => e
        Rails.logger.warn "Failed to close Redis: #{e.message}"
      end
    end

    stream_view_containing_react_components(template: "/pages/rsc_posts_page_over_redis")

    return if redis_thread.join(10)

    redis_thread.kill
    redis_thread.join(1)
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

    redis_thread.kill
    redis_thread.join(1)
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

  # React 19 native metadata examples (no react-helmet)
  def native_metadata
    render "/pages/native_metadata"
  end

  def stream_native_metadata
    stream_view_containing_react_components(template: "/pages/stream_native_metadata")
  end

  def hybrid_metadata_streaming
    @page_title = "#{PROPS_NAME}'s Profile | React on Rails"
    @page_description = "Profile page for #{PROPS_NAME} - metadata set by Rails controller for SEO"
    stream_view_containing_react_components(template: "/pages/hybrid_metadata_streaming")
  end

  def rsc_native_metadata
    stream_view_containing_react_components(template: "/pages/rsc_native_metadata")
  end

  # Demo page showing 10 async components rendering concurrently
  # Each component delays 1 second - sequential would take ~10s, concurrent takes ~1s
  def async_components_demo
    render "/pages/pro/async_components_demo"
  end

  def leak_repro
    @leak_repro_props = build_leak_repro_props
    render "/pages/leak_repro"
  end

  # See files in spec/dummy/app/views/pages

  helper_method :calc_slow_app_props_server_render, :error_hub_config_value

  private

  def build_leak_repro_props # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    rng = Random.new(42)
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor " \
            "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud " \
            "exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure " \
            "dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
    all_tags = %w[Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa Lambda Mu Nu Xi Omicron Pi]
    cities = %w[NewYork London Tokyo Berlin Paris Sydney Toronto Mumbai Shanghai SaoPaulo]
    streets = ["123 Main St", "456 Oak Ave", "789 Pine Rd", "321 Elm Blvd", "654 Cedar Ln",
               "987 Maple Dr", "111 Birch Way", "222 Walnut Ct", "333 Spruce Pl", "444 Ash Ter"]
    categories = %w[Technology Science Health Finance Education Sports Entertainment Travel Food Art]

    items = Array.new(LEAK_REPRO_ITEM_COUNT) do |i|
      color = "##{rng.rand(0x1000000).to_s(16).rjust(6, '0')}"
      {
        id: i,
        title: "Item #{i}: #{lorem[0..80]}",
        body: "#{lorem} #{lorem} #{lorem} Entry number #{i} in the dataset. #{lorem}",
        description: "#{lorem}\n\n#{lorem}\n\n#{lorem}\n\nGenerated for index #{i}.",
        tags: all_tags.sample(8, random: rng),
        author: { name: "user#{rng.rand(10_000)}", email: "user#{rng.rand(10_000)}@example.com",
                  bio: lorem[0..200], avatarUrl: "https://placeholders.example.com/#{rng.rand(9999)}.png" },
        date: "2025-#{format('%02d', rng.rand(1..12))}-#{format('%02d', rng.rand(1..28))}",
        updatedAt: "2025-#{format('%02d',
                                  rng.rand(1..12))}-#{format('%02d',
                                                             rng.rand(1..28))}T#{format('%02d',
                                                                                        rng.rand(0..23))}:#{format(
                                                                                          '%02d', rng.rand(0..59)
                                                                                        )}:00Z",
        score: rng.rand(0..100_000),
        color: color,
        bgColor: "##{rng.rand(0xE00000..0xFFFFFF).to_s(16).rjust(6, '0')}",
        address: { street: streets.sample(random: rng), city: cities.sample(random: rng),
                   state: "ST", zip: format("%05d", rng.rand(10_000..99_999)),
                   country: "US", lat: ((rng.rand * 180) - 90).round(6), lng: ((rng.rand * 360) - 180).round(6) },
        metadata: { category: categories.sample(random: rng),
                    keywords: all_tags.sample(6, random: rng).map(&:downcase),
                    priority: rng.rand(1..5), featured: rng.rand(2).zero?,
                    dimensions: { width: rng.rand(100..4000), height: rng.rand(100..4000) } },
        stats: { views: rng.rand(0..1_000_000), likes: rng.rand(0..50_000),
                 shares: rng.rand(0..10_000), bookmarks: rng.rand(0..5_000),
                 impressions: rng.rand(0..5_000_000), clickRate: (rng.rand * 15).round(2) },
        comments: Array.new(5) do |c|
          { id: "#{i}-#{c}", author: "commenter#{rng.rand(5_000)}",
            text: lorem[0..rng.rand(100..350)], score: rng.rand(-10..500),
            createdAt: "2025-#{format('%02d', rng.rand(1..12))}-#{format('%02d', rng.rand(1..28))}",
            replies: Array.new(3) do |r|
              { id: "#{i}-#{c}-#{r}", author: "replier#{rng.rand(5_000)}",
                text: lorem[0..rng.rand(50..200)], score: rng.rand(-5..200) }
            end }
        end,
        thumbnail: leak_repro_svg_thumbnail(i, color)
      }
    end

    { items: items, generatedAt: Time.now.iso8601, totalCount: LEAK_REPRO_ITEM_COUNT,
      siteConfig: { name: "LeakRepro Benchmark", version: "2.0", locale: "en-US",
                    theme: { primary: "#1a73e8", secondary: "#fbbc04", background: "#ffffff",
                             surface: "#f8f9fa", error: "#d93025", fontFamily: "Inter, system-ui, sans-serif" } } }
  end

  def leak_repro_svg_thumbnail(index, color)
    "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='300' viewBox='0 0 400 300'>" \
      "<rect width='400' height='300' fill='#{color}' opacity='0.15'/>" \
      "<circle cx='200' cy='120' r='60' fill='#{color}' opacity='0.4'/>" \
      "<circle cx='140' cy='180' r='40' fill='#{color}' opacity='0.3'/>" \
      "<circle cx='260' cy='180' r='40' fill='#{color}' opacity='0.3'/>" \
      "<rect x='50' y='220' width='300' height='8' rx='4' fill='#{color}' opacity='0.25'/>" \
      "<rect x='80' y='240' width='240' height='8' rx='4' fill='#{color}' opacity='0.2'/>" \
      "<rect x='110' y='260' width='180' height='8' rx='4' fill='#{color}' opacity='0.15'/>" \
      "<text x='200' y='130' text-anchor='middle' font-size='24' fill='#{color}'>Item #{index}</text>" \
      "<text x='200' y='285' text-anchor='middle' font-size='11' fill='#999'>placeholder-#{index}</text>" \
      "</svg>"
  end

  def calc_slow_app_props_server_render
    msg = <<~MSG
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      calling slow calc_slow_app_props_server_render
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    MSG
    Rails.logger.info msg
    render_to_string(template: "/pages/pro/serialize_props",
                     locals: { name: PROPS_NAME }, formats: :json)
  end

  # Temporarily applies config overrides from query params for the duration of a single request.
  # Restores original values in the ensure block so global state is not permanently mutated.
  #
  # NOTE: This mutates global configuration singletons (ReactOnRails.configuration,
  # ReactOnRailsPro.configuration). In a multi-threaded server like Puma, concurrent requests
  # can observe mutated values during the window between apply and restore. This is acceptable
  # for a single-threaded dev/test dummy app but should NOT be replicated in production code.
  def with_config_overrides
    originals = save_error_config
    apply_error_config_overrides
    yield
  ensure
    restore_error_config(originals)
  end

  def save_error_config
    {
      raise_on_prerender_error: ReactOnRails.configuration.raise_on_prerender_error,
      throw_js_errors: ReactOnRailsPro.configuration.throw_js_errors,
      raise_non_shell: ReactOnRailsPro.configuration.raise_non_shell_server_rendering_errors
    }
  end

  def apply_error_config_overrides
    if params.key?(:raise_on_prerender_error)
      ReactOnRails.configuration.raise_on_prerender_error = error_hub_config_value(:raise_on_prerender_error, nil)
    end
    if params.key?(:throw_js_errors)
      ReactOnRailsPro.configuration.throw_js_errors = error_hub_config_value(:throw_js_errors, nil)
    end
    return unless params.key?(:raise_non_shell_server_rendering_errors)

    ReactOnRailsPro.configuration.raise_non_shell_server_rendering_errors =
      error_hub_config_value(:raise_non_shell_server_rendering_errors, nil)
  end

  def restore_error_config(originals)
    ReactOnRails.configuration.raise_on_prerender_error = originals[:raise_on_prerender_error]
    ReactOnRailsPro.configuration.throw_js_errors = originals[:throw_js_errors]
    ReactOnRailsPro.configuration.raise_non_shell_server_rendering_errors = originals[:raise_non_shell]
  end

  # Casts a query param to boolean. Used by both the error hub view (to display current
  # config state without mutation) and apply_error_config_overrides (to mutate config).
  def error_hub_config_value(key, default)
    value = params[key]
    return default if value.blank?

    ActiveModel::Type::Boolean.new.cast(value)
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
