# frozen_string_literal: true

require "uri"
require "httpx"
require_relative "stream_request"
require_relative "async_props_emitter"

module ReactOnRailsPro
  class Request # rubocop:disable Metrics/ClassLength
    class << self
      # Mutex for thread-safe connection management.
      # Using a constant eliminates the race condition that would exist with @mutex ||= Mutex.new
      CONNECTION_MUTEX = Mutex.new

      def reset_connection
        CONNECTION_MUTEX.synchronize do
          new_conn = create_connection
          old_conn = @connection
          @connection = new_conn
          old_conn&.close
        end
      end

      def render_code(path, js_code, send_bundle)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
        form = form_with_code(js_code, send_bundle)
        perform_request(path, form: form)
      end

      def render_code_as_stream(path, js_code, is_rsc_payload:)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request as a stream #{path}" }
        if is_rsc_payload && !ReactOnRailsPro.configuration.enable_rsc_support
          raise ReactOnRailsPro::Error,
                "RSC support is not enabled. Please set enable_rsc_support to true in your " \
                "config/initializers/react_on_rails_pro.rb file before " \
                "rendering any RSC payload."
        end

        ReactOnRailsPro::StreamRequest.create do |send_bundle, _barrier|
          if send_bundle
            Rails.logger.info { "[ReactOnRailsPro] Sending bundle to the node renderer" }
            upload_assets
          end

          form = form_with_code(js_code, false)
          perform_request(path, form: form, stream: true)
        end
      end

      # Performs an incremental render request with bidirectional HTTP/2 streaming.
      #
      # ARCHITECTURE: This method orchestrates the async props flow:
      #
      # ┌─────────────────────────────────────────────────────────────────────────┐
      # │  Rails Thread (main)              │  Rails Thread (barrier.async)       │
      # ├───────────────────────────────────┼─────────────────────────────────────┤
      # │  1. Send initial NDJSON line      │                                     │
      # │     {renderingRequest, ...}       │                                     │
      # │                                   │                                     │
      # │  2. Return response stream        │  3. Execute async_props_block       │
      # │     (caller processes HTML)       │     emit.call("users", User.all)    │
      # │                                   │     └── Sends NDJSON: {updateChunk} │
      # │                                   │     emit.call("posts", Post.all)    │
      # │                                   │     └── Sends NDJSON: {updateChunk} │
      # │                                   │                                     │
      # │  ... streaming HTML chunks ...    │  4. Block completes                 │
      # │                                   │     request.close (sends END_STREAM)│
      # └───────────────────────────────────┴─────────────────────────────────────┘
      #
      # WHY barrier.async?
      # - We need to return the response stream immediately so Rails can start sending HTML
      # - The async_props_block runs concurrently, sending props as they become available
      # - When the block finishes, we close the request (END_STREAM flag)
      # - Node's handleRequestClosed then calls asyncPropsManager.endStream()
      #
      def render_code_with_incremental_updates(path, js_code, async_props_block:, is_rsc_payload:)
        Rails.logger.info { "[ReactOnRailsPro] Perform incremental rendering request #{path}" }

        # Determine bundle timestamp based on RSC support
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        bundle_timestamp = is_rsc_payload ? pool.rsc_bundle_hash : pool.server_bundle_hash

        ReactOnRailsPro::StreamRequest.create do |send_bundle, barrier|
          if send_bundle
            Rails.logger.info { "[ReactOnRailsPro] Sending bundle to the node renderer" }
            upload_assets
          end

          # Build bidirectional streaming request using HTTPX's stream_bidi plugin.
          # This creates an HTTP/2 stream where we can send data while receiving.
          request = connection.build_request(
            "POST",
            path,
            headers: { "content-type" => "application/x-ndjson" },
            body: [],
            stream: true
          )

          # Create emitter - it will write NDJSON lines to the request stream
          emitter = ReactOnRailsPro::AsyncPropsEmitter.new(bundle_timestamp, request)
          initial_data = build_initial_incremental_request(js_code, emitter)

          # Start the request - response begins streaming immediately
          response = connection.request(request, stream: true)

          # Send the initial render request as first NDJSON line
          request << "#{initial_data.to_json}\n"

          # Execute async props block in a separate fiber via barrier.
          # This runs concurrently with the response streaming back to the client.
          barrier.async do
            async_props_block.call(emitter)
          ensure
            # When the block completes (or raises), close the request.
            # This sends HTTP/2 END_STREAM flag, triggering Node's handleRequestClosed.
            request.close
          end

          response
        end
      end

      def upload_assets
        Rails.logger.info { "[ReactOnRailsPro] Uploading assets" }

        # Check if server bundle exists before trying to upload assets
        server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
        unless File.exist?(server_bundle_path)
          raise ReactOnRailsPro::Error, "Server bundle not found at #{server_bundle_path}. " \
                                        "Please build your bundles before uploading assets."
        end

        # Create a list of bundle timestamps to send to the node renderer
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        target_bundles = [pool.server_bundle_hash]

        # Add RSC bundle if enabled
        if ReactOnRailsPro.configuration.enable_rsc_support
          rsc_bundle_path = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
          unless File.exist?(rsc_bundle_path)
            raise ReactOnRailsPro::Error, "RSC bundle not found at #{rsc_bundle_path}. " \
                                          "Please build your bundles before uploading assets."
          end
          target_bundles << pool.rsc_bundle_hash
        end

        form = form_with_assets_and_bundle
        form["targetBundles"] = target_bundles

        perform_request("/upload-assets", form: form)
      end

      def asset_exists_on_vm_renderer?(filename)
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on node-renderer: #{filename}" }

        form_data = common_form_data

        # Add targetBundles from the current bundle hash and RSC bundle hash
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        target_bundles = [pool.server_bundle_hash]

        target_bundles << pool.rsc_bundle_hash if ReactOnRailsPro.configuration.enable_rsc_support

        form_data["targetBundles"] = target_bundles

        response = perform_request("/asset-exists?filename=#{filename}", json: form_data)
        JSON.parse(response.body)["exists"] == true
      end

      private

      def connection
        # Fast path: return existing connection without locking (lock-free for 99.99% of calls)
        conn = @connection
        return conn if conn

        # Slow path: initialize with lock (only happens once per process)
        CONNECTION_MUTEX.synchronize do
          @connection ||= create_connection
        end
      end

      # Performs HTTP POST requests using the build_request pattern.
      # This approach is required because when stream_bidi plugin is loaded,
      # using connection.post with stream: true causes timeouts (the plugin's
      # empty? method returns false, preventing END_STREAM from being sent).
      #
      # For consistency and to share error handling logic, both streaming and
      # non-streaming requests use build_request with manually encoded bodies.
      def perform_request(path, form: nil, json: nil, stream: false) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        available_retries = ReactOnRailsPro.configuration.renderer_request_retry_limit
        retry_request = true
        while retry_request
          begin
            start_time = Time.now
            response = execute_http_request(path, form: form, json: json, stream: stream)
            raise response.error if response.is_a?(HTTPX::ErrorResponse)

            request_time = Time.now - start_time
            warn_timeout = ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout
            if request_time > warn_timeout
              Rails.logger.warn "Request to #{path} took #{request_time} seconds, expected at most #{warn_timeout}."
            end
            retry_request = false
          rescue HTTPX::TimeoutError => e
            # Testing timeout catching:
            # https://github.com/shakacode/react_on_rails_pro/pull/136#issue-463421204
            if available_retries.zero?
              raise ReactOnRailsPro::Error, "Time out error when getting the response on: #{path}.\n" \
                                            "Original error:\n#{e}\n#{e.backtrace}"
            end
            Rails.logger.info do
              "[ReactOnRailsPro] Timed out trying to make a request to the Node Renderer. " \
                "Retrying #{available_retries} more times..."
            end
            available_retries -= 1
            next
          rescue HTTPX::Error => e # Connection errors or other unexpected errors
            # Such errors are handled by ReactOnRailsPro::StreamRequest instead
            raise if e.is_a?(HTTPX::HTTPError) && stream

            raise ReactOnRailsPro::Error,
                  "Node renderer request failed: #{path}.\nOriginal error:\n#{e}\n#{e.backtrace}"
          end
        end

        Rails.logger.info { "[ReactOnRailsPro] Node Renderer responded" }

        # +response+ can also be an +HTTPX::ErrorResponse+ or an +HTTPX::StreamResponse+, which don't have +#status+.
        if response.is_a?(HTTPX::Response) && response.status == ReactOnRailsPro::STATUS_INCOMPATIBLE
          raise ReactOnRailsPro::Error, response.body
        end

        response
      end

      # Executes an HTTP POST request using build_request pattern.
      # For streaming requests, calls request.close to send END_STREAM flag.
      def execute_http_request(path, form: nil, json: nil, stream: false)
        body, content_type = encode_request_body(form: form, json: json)

        request_options = {
          headers: { "content-type" => content_type },
          body: body
        }
        request_options[:stream] = true if stream

        request = connection.build_request("POST", path, **request_options)
        request.close if stream # Signal end of request body to send END_STREAM flag

        connection.request(request)
      end

      # Encodes request body for use with build_request.
      # Supports both form data (with automatic multipart detection) and JSON data.
      def encode_request_body(form: nil, json: nil)
        if form
          encoder = if HTTPX::Transcoder::Multipart.multipart?(form)
                      HTTPX::Transcoder::Multipart.encode(form)
                    else
                      HTTPX::Transcoder::Form.encode(form)
                    end
          [encoder.to_s, encoder.content_type]
        elsif json
          [JSON.generate(json), "application/json"]
        else
          raise ArgumentError, "Either form: or json: must be provided"
        end
      end

      def form_with_code(js_code, send_bundle)
        form = common_form_data
        form["renderingRequest"] = js_code
        populate_form_with_bundle_and_assets(form, check_bundle: false) if send_bundle
        form
      end

      def populate_form_with_bundle_and_assets(form, check_bundle:)
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

        add_bundle_to_form(
          form,
          bundle_path: ReactOnRails::Utils.server_bundle_js_file_path,
          bundle_file_name: pool.renderer_bundle_file_name,
          bundle_hash: pool.server_bundle_hash,
          check_bundle: check_bundle
        )

        if ReactOnRailsPro.configuration.enable_rsc_support
          add_bundle_to_form(
            form,
            bundle_path: ReactOnRailsPro::Utils.rsc_bundle_js_file_path,
            bundle_file_name: pool.rsc_renderer_bundle_file_name,
            bundle_hash: pool.rsc_bundle_hash,
            check_bundle: check_bundle
          )
        end

        add_assets_to_form(form)
      end

      def add_bundle_to_form(form, bundle_path:, bundle_file_name:, bundle_hash:, check_bundle:)
        raise ReactOnRailsPro::Error, "Bundle not found #{bundle_path}" if check_bundle && !File.exist?(bundle_path)

        form["bundle_#{bundle_hash}"] = {
          body: get_form_body_for_file(bundle_path),
          content_type: "text/javascript",
          filename: bundle_file_name
        }
      end

      def add_assets_to_form(form)
        assets_to_copy = (ReactOnRailsPro.configuration.assets_to_copy || []).dup
        # react_client_manifest and react_server_manifest files are needed to generate react server components payload
        if ReactOnRailsPro.configuration.enable_rsc_support
          assets_to_copy << ReactOnRailsPro::Utils.react_client_manifest_file_path
          assets_to_copy << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
        end

        return form unless assets_to_copy.present?

        assets_to_copy.each_with_index do |asset_path, idx|
          Rails.logger.info { "[ReactOnRailsPro] Uploading asset #{asset_path}" }
          unless http_url?(asset_path) || File.exist?(asset_path)
            warn "Asset not found #{asset_path}"
            next
          end

          content_type = ReactOnRailsPro::Utils.mine_type_from_file_name(asset_path)

          begin
            form["assetsToCopy#{idx}"] = {
              body: get_form_body_for_file(asset_path),
              content_type: content_type,
              filename: File.basename(asset_path)
            }
          rescue StandardError => e
            warn "[ReactOnRailsPro] Error uploading asset #{asset_path}: #{e}"
          end
        end

        form
      end

      def form_with_assets_and_bundle
        form = common_form_data
        populate_form_with_bundle_and_assets(form, check_bundle: true)
        form
      end

      def common_form_data
        ReactOnRailsPro::Utils.common_form_data
      end

      def build_initial_incremental_request(js_code, emitter)
        common_form_data.merge(
          renderingRequest: js_code,
          onRequestClosedUpdateChunk: emitter.end_stream_chunk
        )
      end

      def create_connection # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        url = ReactOnRailsPro.configuration.renderer_url
        Rails.logger.info do
          "[ReactOnRailsPro] Setting up Node Renderer connection to #{url}"
        end
        HTTPX
          # For persistent connections we want retries,
          # so the requests don't just fail if the other side closes the connection
          # https://honeyryderchuck.gitlab.io/httpx/wiki/Persistent
          .plugin(
            :retries, max_retries: 1,
                      retry_change_requests: true,
                      # Official HTTPx docs says that we should use the retry_on option to decide if the
                      # request should be retried or not
                      # However, HTTPx assumes that connection errors such as timeout error should be retried
                      # by default and it doesn't consider retry_on block at all at that case
                      # So, we have to do the following trick to avoid retries when a Timeout error happens
                      # while streaming a component
                      # If the streamed component returned any chunks, it shouldn't retry on errors, as it
                      # would cause page duplication
                      # The SSR-generated html will be written to the page two times in this case
                      retry_after: lambda do |request, response|
                                     if request.stream.instance_variable_get(:@react_on_rails_received_first_chunk)
                                       e = response.error
                                       raise(
                                         ReactOnRailsPro::Error,
                                         "An error happened during server side render streaming " \
                                         "of a component.\nOriginal error:\n#{e}\n#{e.backtrace}"
                                       )
                                     end
                                     Rails.logger.info do
                                       "[ReactOnRailsPro] An error occurred while making " \
                                         "a request to the Node Renderer.\n" \
                                         "Error: #{response.error}.\n" \
                                         "Retrying by HTTPX \"retries\" plugin..."
                                     end
                                     # The retry_after block expects to return a delay to wait before
                                     # retrying the request
                                     # nil means no waiting delay
                                     nil
                                   end
          )
          .plugin(:stream_bidi)
          # See https://www.rubydoc.info/gems/httpx/1.3.3/HTTPX%2FOptions:initialize for the available options
          .with(
            origin: url,
            # Version of HTTP protocol to use by default in the absence of protocol negotiation
            fallback_protocol: "h2",
            persistent: true,
            pool_options: {
              max_connections_per_origin: ReactOnRailsPro.configuration.renderer_http_pool_size
            },
            # Other timeouts supported https://honeyryderchuck.gitlab.io/httpx/wiki/Timeouts:
            # :write_timeout
            # :request_timeout
            # :operation_timeout
            # :keep_alive_timeout
            timeout: {
              connect_timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
              read_timeout: ReactOnRailsPro.configuration.ssr_timeout
            }
          )
      rescue StandardError => e
        message = <<~MSG
          [ReactOnRailsPro] Error creating HTTPX connection.
          renderer_http_pool_size = #{ReactOnRailsPro.configuration.renderer_http_pool_size}
          renderer_http_pool_timeout = #{ReactOnRailsPro.configuration.renderer_http_pool_timeout}
          renderer_http_pool_warn_timeout = #{ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout}
          renderer_url = #{url}
          Be sure to use a url that contains the protocol of http or https.
          Original error is
          #{e}
        MSG
        raise ReactOnRailsPro::Error, message
      end

      def get_form_body_for_file(path)
        # Handles the case when the file is served from the dev server
        if http_url?(path)
          unless Rails.env.development?
            raise ReactOnRailsPro::Error,
                  "Not expected to get HTTP url for bundle or assets in production mode"
          end

          response = HTTPX.get(path)
          response.body
        else
          Pathname.new(path)
        end
      end

      def http_url?(path)
        path.to_s.match?(%r{https?://})
      end
    end
  end
end
