# frozen_string_literal: true

require "async"
require "async/http"
require "async/http/protocol/http2"
require "io/endpoint/version"
require "json"
require "pathname"
require "protocol/http/headers"
require "securerandom"
require "uri"

module ReactOnRailsPro
  class RendererHttpClient # rubocop:disable Metrics/ClassLength
    class Error < StandardError; end

    class TimeoutError < Error; end

    class ConnectionError < Error; end

    IO_ENDPOINT_REQUIREMENT = Gem::Requirement.new("~> 0.17.0")

    class HTTPError < Error
      attr_reader :response

      def initialize(response)
        @response = response
        super("HTTP request failed with status #{response.status}")
      end
    end

    CONNECTION_ERRORS = [
      SocketError,
      IOError,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      Protocol::HTTP::RefusedError,
      # Treat HTTP/2 stream resets as transport failures because the renderer can
      # abort streams without a usable HTTP response for Request/StreamRequest.
      Protocol::HTTP2::StreamError
    ].freeze

    class ConnectTimeoutWrapper < IO::Endpoint::Wrapper
      attr_reader :connect_timeout

      def initialize(connect_timeout)
        # Wrapper is used only for the socket_connect hook; async-http passes it via the wrapper: option and
        # never calls delegation methods on it directly. The no-arg wrapper init and socket_connect dispatch are
        # verified against io-endpoint 0.17.x; re-check them before bumping io-endpoint to 0.18+.
        super()
        @connect_timeout = connect_timeout
      end

      def connect(remote_address, **options)
        socket = super(remote_address, **options.merge({ timeout: connect_timeout }.compact))
        clear_timeout(socket) if connect_timeout

        return socket unless block_given?

        begin
          yield socket
        ensure
          socket.close
        end
      end

      private

      def clear_timeout(socket)
        unless socket.respond_to?(:timeout=)
          raise Error, "#{socket.class} does not support timeout=; re-check io-endpoint socket timeout handling."
        end

        socket.timeout = nil
      end
    end

    # Not thread-safe. Each Response instance is owned and consumed by one renderer request path.
    class Response
      attr_reader :status

      def initialize(status: nil, body: nil, error: nil, &executor)
        @status = status
        @body_chunks = Array(body || [])
        @body = nil
        @error = error
        @executor = executor
        @consumed = false
      end

      def body
        consume unless @consumed
        @body ||= @body_chunks.join
      end

      def error?
        # nil status means a lazy streaming executor has not run yet, so it is not-yet-an-error.
        !status.nil? && status >= 400
      end

      def each(&block)
        return enum_for(:each) unless block

        if @executor && !@consumed
          consume(&block)
        else
          @body_chunks.each(&block)
        end

        # Replaying consumed chunks should still surface the stored response failure.
        raise @error if @error
        raise HTTPError, self if error?
      end

      private

      def append_chunk(chunk)
        @body = nil
        @body_chunks << chunk
      end

      def consume
        return if @consumed

        status_assigner = ->(status) { @status = status }
        yielder = lambda do |chunk|
          append_chunk(chunk)
          yield chunk if block_given?
        end

        # Mark consumed before the executor runs so a raised response still has a determinate replay state:
        # each re-raises @error, while body can return partial chunks for error-body access.
        @consumed = true
        begin
          @executor&.call(yielder, status_assigner)
        rescue StandardError => e
          @error ||= e
          raise
        end
      end
    end

    class << self
      def validate_io_endpoint_version!
        version = Gem::Version.new(IO::Endpoint::VERSION)
        return if IO_ENDPOINT_REQUIREMENT.satisfied_by?(version)

        raise Error, "io-endpoint #{IO::Endpoint::VERSION} is unsupported; async-http renderer client " \
                     "requires #{IO_ENDPOINT_REQUIREMENT} because ConnectTimeoutWrapper relies on " \
                     "IO::Endpoint::Wrapper internals. Pin io-endpoint to #{IO_ENDPOINT_REQUIREMENT} " \
                     "or restore the react_on_rails_pro dependency constraints and run bundle update io-endpoint."
      end

      def get(url, connect_timeout:, read_timeout:)
        origin, path = split_url(url)

        new(
          origin: origin,
          pool_size: 1,
          connect_timeout: connect_timeout,
          read_timeout: read_timeout,
          force_http2: false
        ).get(path)
      end

      def split_url(url)
        uri = URI.parse(url)
        port = uri.port unless uri.default_port == uri.port
        origin = "#{uri.scheme}://#{uri.host}#{":#{port}" if port}"

        [origin, uri.request_uri]
      end

      # boundary must not contain "--"; callers should use the default SecureRandom.hex value.
      def build_multipart_body(form, boundary: SecureRandom.hex(24))
        body = +"".b

        form.each do |name, value|
          append_multipart_value(body, boundary, name, value)
        end

        body << "--#{boundary}--\r\n"

        [
          [["content-type", "multipart/form-data; boundary=#{boundary}"]],
          body
        ]
      end

      def build_form_body(form)
        return build_multipart_body(form) if form.any? { |_name, value| file_part?(value) }

        [
          [["content-type", "application/x-www-form-urlencoded"]],
          URI.encode_www_form(flatten_url_encoded_form(form))
        ]
      end

      private

      def flatten_url_encoded_form(form)
        form.each_with_object([]) do |(name, value), pairs|
          if value.is_a?(Array)
            value.each { |item| pairs << ["#{name}[]", item] }
          else
            pairs << [name, value]
          end
        end
      end

      def append_multipart_value(body, boundary, name, value)
        if value.is_a?(Array)
          value.each { |item| append_scalar_part(body, boundary, "#{name}[]", item) }
        elsif file_part?(value)
          append_file_part(body, boundary, name, value)
        else
          append_scalar_part(body, boundary, name, value)
        end
      end

      def file_part?(value)
        # File parts are Hash values with the renderer upload shape:
        # { body: Pathname/IO/String, filename: String, content_type: String }.
        value.is_a?(Hash) && value.key?(:body)
      end

      def append_scalar_part(body, boundary, name, value)
        name = sanitize_header_param(name)
        body << "--#{boundary}\r\n"
        body << %(Content-Disposition: form-data; name="#{name}"\r\n)
        body << "\r\n"
        body << value.to_s.b
        body << "\r\n"
      end

      def append_file_part(body, boundary, name, value)
        name = sanitize_header_param(name)
        filename = sanitize_header_param(value.fetch(:filename))
        content_type = sanitize_header_value(value.fetch(:content_type))
        body << "--#{boundary}\r\n"
        body << %(Content-Disposition: form-data; name="#{name}"; filename="#{filename}"\r\n)
        body << "Content-Type: #{content_type}\r\n"
        body << "\r\n"
        body << multipart_file_body(value.fetch(:body))
        body << "\r\n"
      end

      def sanitize_header_param(value)
        value.to_s.gsub(/["\\]/) { |char| "\\#{char}" }.delete("\r\n")
      end

      def sanitize_header_value(value)
        value.to_s.delete("\r\n")
      end

      # Bundle files are fully buffered before upload. content-length is omitted
      # because setting it caused Fastify HTTP/2 stream resets during testing.
      def multipart_file_body(body)
        return body.binread if body.is_a?(Pathname)
        return body.read.b if body.respond_to?(:read)

        body.to_s.b
      end
    end

    validate_io_endpoint_version!

    def initialize(origin:, pool_size:, connect_timeout:, read_timeout:, force_http2: true)
      @origin = origin
      @pool_size = pool_size
      @connect_timeout = connect_timeout
      @read_timeout = read_timeout
      @force_h2c = force_http2 && URI.parse(origin).scheme == "http"
    end

    def post(path, form: nil, json: nil, stream: false)
      headers, body = request_body(form: form, json: json)
      build_response(stream: stream) do |yielder, status_assigner|
        execute_request(:post, path, [headers, body], yielder, status_assigner)
      end
    end

    def get(path)
      build_response(stream: false) do |yielder, status_assigner|
        execute_request(:get, path, [[], nil], yielder, status_assigner)
      end
    end

    def close
      # No-op: async-http clients are scoped to individual requests so they never cross Async reactors.
      # Request#reset_connection still calls close for adapter compatibility.
    end

    private

    def request_body(form:, json:)
      if form
        self.class.build_form_body(form)
      elsif json
        [[["content-type", "application/json"]], JSON.generate(json)]
      else
        [[], nil]
      end
    end

    def build_response(stream:, &executor)
      response = Response.new(&executor)

      # Non-streaming requests are consumed here so the HTTP exchange completes before returning.
      # Streaming requests stay lazy; the caller drives the exchange via Response#each.
      response.body unless stream
      response
    end

    def execute_request(method, path, request_body, yielder, status_assigner)
      headers, body = request_body

      run_with_timeout do
        with_client do |client|
          raw_response = if method == :post
                           client.post(path, headers: Protocol::HTTP::Headers[headers], body: body)
                         else
                           client.get(path, headers: Protocol::HTTP::Headers[headers])
                         end

          status_assigner.call(raw_response.status)
          stream_body(raw_response, yielder)
        end
      end
    rescue Async::TimeoutError, IO::TimeoutError => e
      raise TimeoutError, e.message
    rescue *CONNECTION_ERRORS => e
      # Errno::ETIMEDOUT is an OS-level connection failure; async-http request deadlines are rescued above.
      raise ConnectionError, e.message
    end

    def run_with_timeout(&block)
      # @read_timeout carries ssr_timeout and bounds the whole renderer request,
      # including TCP connect, request write, and response body streaming.
      # Async treats nil as no timeout; configuration keeps that legacy escape hatch explicit.
      if (task = Async::Task.current?)
        task.with_timeout(@read_timeout, &block)
      else
        # Rails calls this from a synchronous request thread; Sync blocks that thread
        # while async-http drives the renderer exchange inside a temporary reactor.
        # If an async server reaches this fallback from inside an existing reactor without
        # Async::Task.current?, Sync may create a nested reactor and deadlock; rework this
        # path before supporting that setup.
        Sync { |sync_task| sync_task.with_timeout(@read_timeout, &block) }
      end
    end

    def with_client(&block)
      # TODO: revisit persistent async-http clients for renderer requests once
      # https://github.com/shakacode/react_on_rails/issues/3283 settles connection-reuse direction.
      endpoint = endpoint_for(@origin)
      Async::HTTP::Client.open(endpoint, protocol: endpoint.protocol, retries: 0, limit: pool_limit) do |client|
        # Retries are owned by Request/StreamRequest so bundle-upload retry behavior remains centralized.
        # Each client is intentionally request-scoped to avoid sharing connections across Async reactors.
        # limit is therefore a per-request HTTP/2 stream cap, not a process-wide connection pool size.
        # rubocop:disable Performance/RedundantBlockCall
        # The block is captured with &block, so yield is unavailable in this nested block.
        block.call(client)
        # rubocop:enable Performance/RedundantBlockCall
      end
    end

    def endpoint_for(origin)
      options = { wrapper: ConnectTimeoutWrapper.new(@connect_timeout) }
      options[:protocol] = Async::HTTP::Protocol::HTTP2 if @force_h2c

      Async::HTTP::Endpoint.parse(origin, **options)
    end

    def pool_limit
      # nil preserves the legacy "use the default" setting; async-http still receives a finite stream limit.
      @pool_size || ReactOnRailsPro::Configuration::DEFAULT_RENDERER_HTTP_POOL_SIZE
    end

    def stream_body(raw_response, yielder)
      body = raw_response&.body
      body&.each { |chunk| yielder.call(chunk) }
    ensure
      body&.close
    end
  end
end
