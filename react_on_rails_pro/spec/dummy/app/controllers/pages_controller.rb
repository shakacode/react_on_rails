# frozen_string_literal: true

class PagesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ReactOnRailsPro::RSCPayloadRenderer
  include RscPostsPageOverRedisHelper
  include ReactOnRailsPro::AsyncRendering

  enable_async_react_rendering only: [:async_components_demo]

  XSS_PAYLOAD = { "<script>window.alert('xss1');</script>" => '<script>window.alert("xss2");</script>' }.freeze
  # Constants for random data generation (extracted to avoid Performance/CollectionLiteralInLoop)
  COLORS = %w[red green blue yellow purple].freeze
  SIZES = %w[small medium large xlarge].freeze
  PROPS_NAME = "Mr. Server Side Rendering"
  APP_PROPS_SERVER_RENDER = {
    helloWorldData: {
      name: PROPS_NAME
    }.merge(XSS_PAYLOAD)
  }.freeze

  before_action do
    session[:something_useful] = "REALLY USEFUL"
  end

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

  def stream_async_components
    stream_view_containing_react_components(template: "/pages/stream_async_components")
  end

  def stream_async_components_for_testing
    stream_view_containing_react_components(template: "/pages/stream_async_components_for_testing")
  end

  def cached_stream_async_components_for_testing
    stream_view_containing_react_components(template: "/pages/cached_stream_async_components_for_testing")
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

  # Large props stress test for reproducing JSON parsing race condition
  # https://github.com/shakacode/react_on_rails/issues/2283
  def large_props_stress_test
    # Get registration delay from params (default 100ms)
    @registration_delay = (params[:delay] || 100).to_i
    # Get props size multiplier from params (default 1 = ~200KB, 5 = ~1MB)
    @size_multiplier = (params[:size] || 1).to_i.clamp(1, 10)

    # Generate large props to trigger the race condition
    @large_props_first = generate_large_props(1, @size_multiplier)
    @large_props_second = generate_large_props(2, @size_multiplier)
    @large_props_array = (0..2).map { |i| generate_large_props(i + 10, @size_multiplier) }

    # Calculate total props size for display
    all_props = [@large_props_first, @large_props_second] + @large_props_array
    @total_props_size = all_props.sum { |p| p.to_json.length }
  end

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

  # Generate large props data (~200KB * multiplier when serialized to JSON)
  def generate_large_props(component_id, size_multiplier = 1)
    items = build_large_items_array(size_multiplier)
    build_props_hash(component_id, items)
  end

  def build_large_items_array(size_multiplier = 1)
    # Create a large nested structure (~200KB * multiplier)
    item_count = 500 * size_multiplier
    (0...item_count).map do |i|
      {
        id: i,
        uuid: SecureRandom.uuid,
        name: "Item #{i} with a reasonably long name to increase size",
        description: "This is a detailed description for item #{i}. " * 10,
        metadata: build_item_metadata(i)
      }
    end
  end

  def build_item_metadata(index)
    {
      created_at: Time.now.iso8601,
      updated_at: Time.now.iso8601,
      tags: %w[tag1 tag2 tag3 tag4 tag5],
      attributes: {
        color: COLORS.sample,
        size: SIZES.sample,
        weight: rand(1.0..100.0).round(2),
        dimensions: { width: rand(10..100), height: rand(10..100), depth: rand(10..100) }
      },
      # Add some special characters that could potentially cause issues
      special_chars: "Special: <script>alert('xss')</script> & \"quotes\" 'apostrophe' \u2028\u2029",
      nested_array: (0..10).map { |j| { nested_id: j, value: "nested_value_#{index}_#{j}" * 5 } }
    }
  end

  def build_props_hash(component_id, items)
    {
      componentId: component_id,
      loadTime: Time.now.iso8601,
      registrationDelay: @registration_delay,
      largeData: {
        items: items,
        summary: {
          totalItems: items.length,
          generatedAt: Time.now.iso8601,
          propsVersion: "1.0.0"
        }
      }
    }
  end
end
