# frozen_string_literal: true

require "async"
require "async/http"
require "async/http/protocol/http2"
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
        # never calls delegation methods on it directly. Verified against io-endpoint 0.17.x.
        super()
        @connect_timeout = connect_timeout
      end

      def connect(remote_address, **options)
        socket = super(remote_address, **options.merge(connect_timeout ? { timeout: connect_timeout } : {}))
        clear_timeout(socket)

        return socket unless block_given?

        begin
          yield socket
        ensure
          socket.close
        end
      end

      private

      def clear_timeout(socket)
        socket.timeout = nil if socket.respond_to?(:timeout=)
      end
    end

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
      # Request#reset_connection still calls close for adapter compatibility.
      # async-http clients are scoped to individual requests so they never cross Async reactors.
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
      raise ConnectionError, e.message
    end

    def run_with_timeout(&block)
      # @read_timeout carries ssr_timeout and bounds the whole renderer request,
      # including TCP connect, request write, and response body streaming.
      if (task = Async::Task.current?)
        task.with_timeout(@read_timeout, &block)
      else
        # Rails calls this from a synchronous request thread; Sync blocks that thread
        # while async-http drives the renderer exchange inside a temporary reactor.
        Sync { |sync_task| sync_task.with_timeout(@read_timeout, &block) }
      end
    end

    def with_client(&block)
      endpoint = endpoint_for(@origin)
      Async::HTTP::Client.open(endpoint, protocol: endpoint.protocol, retries: 0, limit: @pool_size) do |client|
        # Retries are owned by Request/StreamRequest so bundle-upload retry behavior remains centralized.
        # Each client is intentionally request-scoped to avoid sharing connections across Async reactors.
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

    def stream_body(raw_response, yielder)
      body = raw_response&.body
      body&.each { |chunk| yielder.call(chunk) }
    ensure
      body&.close
    end
  end
end
