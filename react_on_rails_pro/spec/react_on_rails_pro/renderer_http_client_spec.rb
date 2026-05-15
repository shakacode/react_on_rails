# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/renderer_http_client"

RSpec.describe ReactOnRailsPro::RendererHttpClient do
  describe ReactOnRailsPro::RendererHttpClient::ConnectTimeoutWrapper do
    it "clears the socket timeout after TCP connect" do
      wrapper = described_class.new(0.25)
      socket = nil
      timeout_during_connect = nil

      allow(wrapper).to receive(:socket_connect) do |connecting_socket, _remote_address|
        timeout_during_connect = connecting_socket.timeout
      end

      socket = wrapper.connect(Addrinfo.tcp("127.0.0.1", 80))

      expect(timeout_during_connect).to eq(0.25)
      expect(socket.timeout).to be_nil
    ensure
      socket&.close
    end
  end

  describe ReactOnRailsPro::RendererHttpClient::Response do
    it "does not treat an unknown status as an error" do
      response = described_class.new

      expect(response).not_to be_error
    end

    it "does not expose a public status writer" do
      response = described_class.new(status: 200)

      expect(response).not_to respond_to(:status=)
    end

    it "yields streamed chunks and raises an HTTPError after consuming an error response" do
      response = described_class.new(status: 410, body: ["Bundle ", "Required"])
      chunks = []

      expect do
        response.each { |chunk| chunks << chunk }
      end.to raise_error(ReactOnRailsPro::RendererHttpClient::HTTPError) { |error|
        expect(error.response).to be(response)
        expect(error.response.body).to eq("Bundle Required")
      }

      expect(chunks).to eq(["Bundle ", "Required"])
    end
  end

  describe ".build_multipart_body" do
    it "encodes scalar, array, and uploaded file fields" do
      Tempfile.create(["react-on-rails-pro", ".js"]) do |file|
        file.write("console.log('bundle');")
        file.rewind

        form = {
          "password" => "secret",
          "targetBundles" => %w[server rsc],
          "bundle_server" => {
            body: Pathname.new(file.path),
            content_type: "text/javascript",
            filename: "server.js"
          }
        }

        headers, body = described_class.build_multipart_body(form, boundary: "rorp-test-boundary")

        expect(headers).to include(["content-type", "multipart/form-data; boundary=rorp-test-boundary"])
        expect(headers).not_to include(["content-length", body.bytesize.to_s])
        expect(body).to include('name="password"')
        expect(body).to include("secret")
        expect(body).to include('name="targetBundles[]"')
        expect(body).to include("server")
        expect(body).to include("rsc")
        expect(body).to include('name="bundle_server"; filename="server.js"')
        expect(body).to include("Content-Type: text/javascript")
        expect(body).to include("console.log('bundle');")
      end
    end

    it "escapes header parameters in content disposition fields" do
      headers, body = described_class.build_multipart_body(
        {
          "field\"name\r\n" => "value",
          "bundle" => {
            body: "console.log('bundle');",
            content_type: "text/javascript\r\nX-Injected: true",
            filename: "server\"\r\nbundle.js"
          }
        },
        boundary: "rorp-test-boundary"
      )

      expect(headers).to include(["content-type", "multipart/form-data; boundary=rorp-test-boundary"])
      expect(body).to include('name="field\"name"')
      expect(body).to include('name="bundle"; filename="server\"bundle.js"')
      expect(body).to include("Content-Type: text/javascriptX-Injected: true\r\n")
      expect(body).not_to include("field\"name\r\n")
      expect(body).not_to include("server\"\r\nbundle.js")
      expect(body).not_to include("\r\nX-Injected")
    end

    it "supports binary uploaded file bodies" do
      binary_payload = [0xff, 0xfe, 0x00, 0x61].pack("C*")
      headers = nil
      body = nil

      expect do
        headers, body = described_class.build_multipart_body(
          {
            "bundle" => {
              body: binary_payload,
              content_type: "application/octet-stream",
              filename: "bundle.bin"
            }
          },
          boundary: "rorp-test-boundary"
        )
      end.not_to raise_error

      expect(headers).to include(["content-type", "multipart/form-data; boundary=rorp-test-boundary"])
      expect(body.encoding).to eq(Encoding::BINARY)
      expect(body.b).to include(binary_payload)
    end
  end

  describe ".build_form_body" do
    it "uses url-encoded form data when no uploaded files are present" do
      headers, body = described_class.build_form_body(
        {
          "password" => "secret",
          "targetBundles" => %w[server rsc],
          "renderingRequest" => "console.log('Hello, world!');"
        }
      )

      expect(headers).to eq([["content-type", "application/x-www-form-urlencoded"]])
      expect(body).to include("password=secret")
      expect(body).to include("targetBundles%5B%5D=server")
      expect(body).to include("targetBundles%5B%5D=rsc")
      expect(body).to include("renderingRequest=console.log")
    end

    it "uses multipart form data when uploaded files are present" do
      Tempfile.create(["react-on-rails-pro", ".js"]) do |file|
        form = {
          "password" => "secret",
          "bundle_server" => {
            body: Pathname.new(file.path),
            content_type: "text/javascript",
            filename: "server.js"
          }
        }

        headers, body = described_class.build_form_body(form)

        expect(headers).to contain_exactly(
          a_collection_containing_exactly("content-type", a_string_starting_with("multipart/form-data; boundary="))
        )
        expect(body).to include('name="bundle_server"; filename="server.js"')
      end
    end
  end

  describe ".get" do
    it "does not force HTTP/2 for arbitrary dev-server asset URLs" do
      response = described_class::Response.new(status: 200, body: ["asset"])
      client = instance_double(described_class, get: response)

      allow(described_class).to receive(:new).and_return(client)

      expect(described_class.get("http://localhost:3035/packs/server.js", connect_timeout: 1, read_timeout: 2))
        .to be(response)

      expect(described_class).to have_received(:new).with(
        origin: "http://localhost:3035",
        pool_size: 1,
        connect_timeout: 1,
        read_timeout: 2,
        force_http2: false
      )
    end
  end

  describe "#post" do
    it "does not install the connect timeout as the endpoint socket operation timeout" do
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 5)
      endpoint = client.__send__(:endpoint_for, "http://localhost:3800")

      expect(endpoint.endpoint.options).to include(wrapper: an_instance_of(described_class::ConnectTimeoutWrapper))
      expect(endpoint.endpoint.options).not_to include(:timeout)
    end

    it "defers streaming requests until response enumeration and sends encoded JSON" do
      response_body = Class.new do
        attr_reader :closed

        def initialize(chunks)
          @chunks = chunks
          @closed = false
        end

        def each(&block)
          @chunks.each(&block)
        end

        def close
          @closed = true
        end
      end.new(%w[render ed])
      stub_const(
        "FakeAsyncPostResponse",
        Class.new do
          def status; end

          def body; end
        end
      )
      stub_const(
        "FakeAsyncPostClient",
        Class.new do
          def post(_path, headers:, body:); end
        end
      )
      raw_response = instance_double(FakeAsyncPostResponse, status: 200, body: response_body)
      async_client = instance_double(FakeAsyncPostClient)
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

      allow(async_client).to receive(:post) do |path, headers:, body:|
        expect(path).to eq("/render")
        expect(headers["content-type"]).to eq("application/json")
        expect(body).to eq({ renderingRequest: "render()" }.to_json)
        raw_response
      end
      allow(client).to receive(:with_client).and_yield(async_client)

      response = client.post("/render", json: { renderingRequest: "render()" }, stream: true)

      expect(async_client).not_to have_received(:post)

      chunks = []
      response.each { |chunk| chunks << chunk }

      expect(async_client).to have_received(:post).once
      expect(response.status).to eq(200)
      expect(chunks).to eq(%w[render ed])
      expect(response.body).to eq("rendered")
      expect(response_body.closed).to be(true)
    end
  end

  describe "#get" do
    it "assigns response status internally while streaming the body" do
      response_body = Class.new do
        attr_reader :closed

        def initialize(chunks)
          @chunks = chunks
          @closed = false
        end

        def each(&block)
          @chunks.each(&block)
        end

        def close
          @closed = true
        end
      end.new(["asset"])
      stub_const(
        "FakeAsyncResponse",
        Class.new do
          def status; end

          def body; end
        end
      )
      stub_const(
        "FakeAsyncClient",
        Class.new do
          def get(_path); end
        end
      )
      raw_response = instance_double(FakeAsyncResponse, status: 204, body: response_body)
      async_client = instance_double(FakeAsyncClient, get: raw_response)
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

      allow(client).to receive(:with_client).and_yield(async_client)

      response = client.get("/asset")

      expect(response.status).to eq(204)
      expect(response.body).to eq("asset")
      expect(response_body.closed).to be(true)
    end

    it "closes the same response body object that it streams" do
      response_body = Class.new do
        attr_reader :closed

        def initialize(chunks)
          @chunks = chunks
          @closed = false
        end

        def each(&block)
          @chunks.each(&block)
        end

        def close
          @closed = true
        end
      end.new(["asset"])
      raw_response = Class.new do
        attr_reader :body_calls, :status

        def initialize(body)
          @body = body
          @body_calls = 0
          @status = 200
        end

        def body
          @body_calls += 1
          @body_calls == 1 ? @body : nil
        end
      end.new(response_body)
      stub_const(
        "FakeAsyncOneShotBodyClient",
        Class.new do
          def get(_path); end
        end
      )
      async_client = instance_double(FakeAsyncOneShotBodyClient, get: raw_response)
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

      allow(client).to receive(:with_client).and_yield(async_client)

      response = client.get("/asset")

      expect(response.body).to eq("asset")
      expect(raw_response.body_calls).to eq(1)
      expect(response_body.closed).to be(true)
    end

    [
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      Errno::ETIMEDOUT
    ].each do |error_class|
      it "wraps #{error_class} in a ConnectionError" do
        client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

        allow(client).to receive(:with_client).and_raise(error_class)

        expect { client.get("/render") }
          .to raise_error(ReactOnRailsPro::RendererHttpClient::ConnectionError)
      end
    end

    it "wraps TCP connection refusals in a ConnectionError with the original message" do
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

      allow(client).to receive(:with_client).and_raise(Errno::ECONNREFUSED)

      expect { client.get("/render") }
        .to raise_error(ReactOnRailsPro::RendererHttpClient::ConnectionError, /Connection refused/)
    end

    it "wraps body read timeouts and closes the response body" do
      response_body = Class.new do
        attr_reader :closed

        def each
          raise IO::TimeoutError, "read timed out"
        end

        def close
          @closed = true
        end
      end.new
      stub_const(
        "FakeAsyncTimeoutResponse",
        Class.new do
          def status; end

          def body; end
        end
      )
      stub_const(
        "FakeAsyncTimeoutClient",
        Class.new do
          def get(_path); end
        end
      )
      raw_response = instance_double(FakeAsyncTimeoutResponse, status: 200, body: response_body)
      async_client = instance_double(FakeAsyncTimeoutClient, get: raw_response)
      client = described_class.new(origin: "http://localhost:3800", pool_size: 1, connect_timeout: 1, read_timeout: 1)

      allow(client).to receive(:with_client).and_yield(async_client)

      expect { client.get("/render") }
        .to raise_error(ReactOnRailsPro::RendererHttpClient::TimeoutError, /read timed out/)
      expect(response_body.closed).to be(true)
    end
  end
end
