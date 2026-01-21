# frozen_string_literal: true

require "uri"
require "async"
require "async/queue"
require "async/http"
require "async/http/endpoint"
require "async/http/client"
require "async/http/body/writable"
require "async/http/protocol/http2"
require "protocol/http/request"
require "protocol/http/headers"
require "protocol/http/body/buffered"
require_relative "stream_request"
require_relative "async_props_emitter"

module ReactOnRailsPro
  class Request # rubocop:disable Metrics/ClassLength
    # Custom error class for async-http errors (replacing HTTPX error types)
    class HTTPError < StandardError
      attr_reader :response, :status, :body

      def initialize(message, response: nil, status: nil, body: nil)
        super(message)
        @response = response
        @status = status || response&.status
        @body = body || ""
      end
    end

    class TimeoutError < HTTPError; end
    class ReadTimeoutError < TimeoutError; end
    class ConnectionError < HTTPError; end

    class << self
      # Mutex for thread-safe connection management.
      # Using a constant eliminates the race condition that would exist with @mutex ||= Mutex.new
      CONNECTION_MUTEX = Mutex.new

      def reset_connection
        CONNECTION_MUTEX.synchronize do
          new_client, new_endpoint = create_connection
          old_client = @client
          @client = new_client
          @endpoint = new_endpoint
          old_client&.close
        end
      end

      def render_code(path, js_code, send_bundle)
        Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
        # Sync provides the async task context required by async-http.
        # This is necessary because render_code is called from regular Rails request context,
        # unlike streaming methods which use StreamRequest (which has its own Sync block).
        #
        # IMPORTANT: We must read the response body INSIDE the Sync block because
        # the HTTP/2 stream lives in the async context. When Sync ends, the context
        # is torn down and the stream becomes invalid.
        Sync do
          form = form_with_code(js_code, send_bundle)
          response = perform_request(path, form: form)

          # Handle STATUS_SEND_BUNDLE - retry with bundle upload
          if response.status == ReactOnRailsPro::STATUS_SEND_BUNDLE
            # Prevent infinite loop
            ReactOnRailsPro::Error.raise_duplicate_bundle_upload_error if send_bundle

            Rails.logger.info { "[ReactOnRailsPro] Received STATUS_SEND_BUNDLE, uploading bundle and retrying" }
            # Consume the response body to close the stream before retrying
            response.read

            # Upload bundle and retry
            form_with_bundle = form_with_code(js_code, true)
            response = perform_request(path, form: form_with_bundle)
          end

          # Read and return body content within async context
          response.read
        end
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
      # │                                   │     request_body.close (END_STREAM) │
      # └───────────────────────────────────┴─────────────────────────────────────┘
      #
      # WHY barrier.async?
      # - We need to return the response stream immediately so Rails can start sending HTML
      # - The async_props_block runs concurrently, sending props as they become available
      # - When the block finishes, we close the request body (END_STREAM flag)
      # - Node's handleRequestClosed then calls asyncPropsManager.endStream()
      #
      def render_code_with_incremental_updates(path, js_code, async_props_block:)
        Rails.logger.info { "[ReactOnRailsPro] Perform incremental rendering request #{path}" }

        # Determine bundle timestamp based on RSC support
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

        ReactOnRailsPro::StreamRequest.create do |send_bundle, barrier| # rubocop:disable Metrics/BlockLength
          if send_bundle
            Rails.logger.info { "[ReactOnRailsPro] Sending bundle to the node renderer" }
            upload_assets
          end

          # Create a writable body for bidirectional streaming with async-http.
          # This allows us to send data while receiving the response.
          # See: https://www.codeotaku.com/journal/2019-01/streaming-http-for-ruby/index
          request_body = Async::HTTP::Body::Writable.new

          # Create emitter - it will write NDJSON lines to the request body
          emitter = ReactOnRailsPro::AsyncPropsEmitter.new(pool.rsc_bundle_hash, request_body)
          initial_data = build_initial_incremental_request(js_code, emitter)

          # Start a fiber to handle all writing to the request body.
          # This fiber runs CONCURRENTLY with client.post, allowing bidirectional streaming.
          #
          # CRITICAL: The server waits for initial data before sending response headers.
          # If we don't start writing before/during client.post, we get a deadlock:
          #   - client.post waits for response headers
          #   - server waits for request body data
          #
          # By spawning this fiber first, the initial write happens as soon as we yield
          # (which happens inside client.post when it waits for I/O).
          barrier.async do
            # Send the initial render request as first NDJSON line
            request_body.write("#{initial_data.to_json}\n")

            # Execute async props block to send additional props
            async_props_block.call(emitter)
          rescue Protocol::HTTP::Body::Writable::Closed
            # Body was closed (likely due to error response like 410).
            # This is expected when the server rejects the request before we finish writing.
            Rails.logger.debug { "[ReactOnRailsPro] Request body closed during async props emission" }
          ensure
            # Signal that no more data will be written.
            # Use close_write() to preserve any pending data for transmission.
            # If the body is already closed (error case), this is a no-op.
            request_body.close_write rescue nil # rubocop:disable Style/RescueModifier

            # Wait for all data to be transmitted, but with a safety check.
            # If the HTTP/2 stream was closed due to an error (e.g., 410), the queue
            # might never drain because the data can't be transmitted. In that case,
            # we break out after a reasonable number of yields to avoid hanging.
            #
            # Normal case: empty? returns true quickly after data is transmitted.
            # Error case: We yield a few times to give a chance for cleanup, then exit.
            max_yields = 100
            yield_count = 0
            until request_body.empty? || yield_count >= max_yields
              Async::Task.current.yield
              yield_count += 1
            end
          end

          # Start the request - the write fiber above runs concurrently.
          # client.post will yield when waiting for I/O, allowing the write fiber to execute.
          response = client.post(
            path,
            Protocol::HTTP::Headers[{ "content-type" => "application/x-ndjson" }],
            request_body
          )

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

        # Sync provides the async task context required by async-http.
        # This method can be called from both async contexts (StreamRequest) and
        # non-async contexts (rake tasks, utils). Sync is re-entrant, so nested
        # calls work correctly when already inside an async context.
        Sync do
          perform_request("/upload-assets", form: form)
        end
      end

      def asset_exists_on_vm_renderer?(filename)
        Rails.logger.info { "[ReactOnRailsPro] Sending request to check if file exist on node-renderer: #{filename}" }

        form_data = common_form_data

        # Add targetBundles from the current bundle hash and RSC bundle hash
        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        target_bundles = [pool.server_bundle_hash]

        target_bundles << pool.rsc_bundle_hash if ReactOnRailsPro.configuration.enable_rsc_support

        form_data["targetBundles"] = target_bundles

        # Sync provides the async task context required by async-http.
        Sync do
          response = perform_request("/asset-exists?filename=#{filename}", json: form_data)
          JSON.parse(response.read)["exists"] == true
        end
      end

      private

      def client
        # Fast path: return existing client without locking (lock-free for 99.99% of calls)
        c = @client
        return c if c

        # Slow path: initialize with lock (only happens once per process)
        CONNECTION_MUTEX.synchronize do
          @client, @endpoint = create_connection unless @client
          @client
        end
      end

      def endpoint
        client # Ensure connection is initialized
        @endpoint
      end

      # Performs HTTP POST requests with retry logic.
      # Implements equivalent behavior to HTTPX's retries plugin.
      def perform_request(path, form: nil, json: nil, stream: false) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        available_retries = ReactOnRailsPro.configuration.renderer_request_retry_limit
        retry_request = true
        received_first_chunk = false
        response = nil

        while retry_request
          begin
            start_time = Time.now
            response = execute_http_request(path, form: form, json: json)

            # Check for error status - must consume body to close HTTP/2 stream
            # For streaming requests, raise HTTPError for all 4xx status codes so StreamRequest can handle them
            # For non-streaming requests, exclude special status codes handled separately:
            # - STATUS_SEND_BUNDLE (410): Triggers bundle upload and retry
            # - STATUS_INCOMPATIBLE: Handled separately below
            status = response.status
            should_raise_error = if stream
                                   status >= 400
                                 else
                                   status >= 400 &&
                                     status != ReactOnRailsPro::STATUS_SEND_BUNDLE &&
                                     status != ReactOnRailsPro::STATUS_INCOMPATIBLE
                                 end
            if should_raise_error
              body_content = response.read # Consume body to properly close the HTTP/2 stream
              error = HTTPError.new(
                "HTTP error #{status}: #{body_content}",
                response: response,
                status: status,
                body: body_content
              )
              raise error
            end

            request_time = Time.now - start_time
            warn_timeout = ReactOnRailsPro.configuration.renderer_http_pool_warn_timeout
            if request_time > warn_timeout
              Rails.logger.warn "Request to #{path} took #{request_time} seconds, expected at most #{warn_timeout}."
            end
            retry_request = false
          rescue Async::TimeoutError, IOError => e
            # Ensure response is cleaned up on error
            finish_response(response)

            # Handle timeout errors with retry logic
            if received_first_chunk
              # Don't retry if we've already received data - would cause duplicate content
              raise ReactOnRailsPro::Error,
                    "An error happened during server side render streaming " \
                    "of a component.\nOriginal error:\n#{e}\n#{e.backtrace}"
            end

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
          rescue HTTPError => e
            # HTTP errors are handled by ReactOnRailsPro::StreamRequest for streaming
            raise if stream

            raise ReactOnRailsPro::Error,
                  "Node renderer request failed: #{path}.\nOriginal error:\n#{e}\n#{e.backtrace}"
          rescue StandardError => e
            # Ensure response is cleaned up on unexpected errors
            finish_response(response)

            # Connection errors or other unexpected errors
            raise ReactOnRailsPro::Error,
                  "Node renderer request failed: #{path}.\nOriginal error:\n#{e}\n#{e.backtrace}"
          end
        end

        Rails.logger.info { "[ReactOnRailsPro] Node Renderer responded" }

        # Check for incompatible status
        raise ReactOnRailsPro::Error, response.read if response.status == ReactOnRailsPro::STATUS_INCOMPATIBLE

        response
      end

      # Safely finish/close a response to release HTTP/2 stream resources
      def finish_response(response)
        return unless response

        response.body&.close
      rescue StandardError
        # Ignore errors during cleanup
      end

      # Executes an HTTP POST request using async-http.
      # Note: For bidirectional streaming, render_code_with_incremental_updates
      # handles the request directly using Body::Writable.
      def execute_http_request(path, form: nil, json: nil)
        body_content, content_type = encode_request_body(form: form, json: json)
        headers = Protocol::HTTP::Headers[{ "content-type" => content_type }]

        # Create a proper body that async-http can send
        # Protocol::HTTP::Body::Buffered wraps the content for proper HTTP body handling
        request_body = Protocol::HTTP::Body::Buffered.wrap(body_content)

        client.post(path, headers, request_body)
      end

      # Encodes request body for HTTP request.
      # Supports both form data (with automatic multipart detection) and JSON data.
      def encode_request_body(form: nil, json: nil)
        if form
          if multipart?(form)
            encode_multipart(form)
          else
            encode_form(form)
          end
        elsif json
          [JSON.generate(json), "application/json"]
        else
          raise ArgumentError, "Either form: or json: must be provided"
        end
      end

      # Check if form contains file uploads (multipart)
      def multipart?(form)
        form.any? do |_key, value|
          value.is_a?(Hash) && value[:body] && value[:filename]
        end
      end

      # Encode as URL-encoded form
      def encode_form(form)
        encoded = URI.encode_www_form(form.reject { |_, v| v.is_a?(Hash) })
        [encoded, "application/x-www-form-urlencoded"]
      end

      # Encode as multipart form data
      def encode_multipart(form)
        boundary = "----ReactOnRailsPro#{SecureRandom.hex(16)}"
        parts = []

        form.each do |key, value|
          if value.is_a?(Hash) && value[:body]
            encode_multipart_file(parts, boundary, key, value)
          elsif value.is_a?(Array)
            encode_multipart_array(parts, boundary, key, value)
          else
            encode_multipart_field(parts, boundary, key, value)
          end
        end

        parts << "--#{boundary}--\r\n"
        [parts.join, "multipart/form-data; boundary=#{boundary}"]
      end

      def encode_multipart_file(parts, boundary, key, value)
        body_content = value[:body]
        body_content = body_content.read if body_content.respond_to?(:read)
        filename = value[:filename] || "file"
        content_type = value[:content_type] || "application/octet-stream"

        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{filename}\"\r\n"
        parts << "Content-Type: #{content_type}\r\n\r\n"
        parts << body_content.to_s
        parts << "\r\n"
      end

      # Encode array field as multiple fields with [] suffix.
      # This is how multipart parsers expect arrays (e.g., fastify's @fastify/multipart)
      def encode_multipart_array(parts, boundary, key, value)
        value.each do |item|
          parts << "--#{boundary}\r\n"
          parts << "Content-Disposition: form-data; name=\"#{key}[]\"\r\n\r\n"
          parts << item.to_s
          parts << "\r\n"
        end
      end

      def encode_multipart_field(parts, boundary, key, value)
        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
        parts << value.to_s
        parts << "\r\n"
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

      def create_connection
        url = ReactOnRailsPro.configuration.renderer_url
        Rails.logger.info do
          "[ReactOnRailsPro] Setting up Node Renderer connection to #{url}"
        end

        # Create endpoint with timeout configuration
        # Force HTTP/2 protocol - the Node renderer always uses HTTP/2 (h2c for plain HTTP)
        # This is required because async-http defaults to HTTP/1.1 for non-TLS connections
        endpoint = Async::HTTP::Endpoint.parse(
          url,
          timeout: ReactOnRailsPro.configuration.renderer_http_pool_timeout,
          protocol: Async::HTTP::Protocol::HTTP2
        )

        # Create client with connection pool limit and retry configuration
        # Note: async-http handles retries internally, but we also have custom retry logic
        # in perform_request for more control over streaming scenarios
        new_client = Async::HTTP::Client.new(
          endpoint,
          retries: 1, # Basic retry for connection issues
          limit: ReactOnRailsPro.configuration.renderer_http_pool_size
        )

        [new_client, endpoint]
      rescue StandardError => e
        message = <<~MSG
          [ReactOnRailsPro] Error creating async-http connection.
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

          # Use a simple HTTP GET for development server files
          Sync do
            dev_endpoint = Async::HTTP::Endpoint.parse(path)
            dev_client = Async::HTTP::Client.new(dev_endpoint)
            response = dev_client.get(URI.parse(path).path)
            body = response.read
            dev_client.close
            body
          end
        else
          File.read(path)
        end
      end

      def http_url?(path)
        path.to_s.match?(%r{https?://})
      end
    end
  end
end
