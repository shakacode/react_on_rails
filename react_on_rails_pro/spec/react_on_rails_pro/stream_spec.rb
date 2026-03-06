# frozen_string_literal: true

require "async"
require "async/queue"
require "async/variable"
require "stringio"
require "zlib"
require_relative "spec_helper"

class StreamController
  include ReactOnRailsPro::Stream

  attr_reader :response, :request

  def initialize(component_queues:, initial_response: "TEMPLATE")
    @component_queues = component_queues
    @initial_response = initial_response
    @request = nil
  end

  def render_to_string(**_opts)
    # Simulate component helpers creating async tasks
    # In real implementation, first chunks are part of template HTML
    # For testing, we enqueue all chunks including first ones
    @component_queues.each do |queue|
      @async_barrier.async do
        loop do
          chunk = queue.dequeue
          break if chunk.nil?

          @main_output_queue.enqueue(chunk)
        end
      end
    end

    @initial_response
  end
end

RSpec.describe "Streaming API" do
  let(:origin) { "http://api.example.com" }
  let(:path) { "/stream" }
  let(:url) { "#{origin}#{path}" }
  let(:http) do
    HTTPX.plugin(:mock_stream)
         .plugin(:retries, max_retries: 1, retry_change_requests: true)
         .plugin(:stream)
         .with(
           origin: url,
           # Version of HTTP protocol to use by default in the absence of protocol negotiation
           fallback_protocol: "h2",
           max_concurrent_requests: 10,
           persistent: true,
           # Other timeouts supported https://honeyryderchuck.gitlab.io/httpx/wiki/Timeouts:
           # :write_timeout
           # :request_timeout
           # :operation_timeout
           # :keep_alive_timeout
           timeout: {
             connect_timeout: 30,
             read_timeout: 30
           }
         )
  end

  before do
    clear_stream_mocks
  end

  it "yields chunk immediately" do
    mocked_block = mock_block
    mock_streaming_response(url, 200) do |yielder|
      yielder.call("First chunk\n")
      expect(mocked_block).to have_received(:call).with("First chunk")

      yielder.call("Second chunk\n")
      expect(mocked_block).to have_received(:call).with("Second chunk")

      yielder.call("Final chunk\n")
      expect(mocked_block).to have_received(:call).with("Final chunk")
    end

    response = http.get(path, stream: true)
    response.each_line(&mocked_block.block)
  end

  describe "raise_for_status" do
    it "is not blocking" do
      mocked_block = mock_block

      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk\n")
        expect(mocked_block).to have_received(:call).with("First chunk")

        yielder.call("Second chunk\n")
        expect(mocked_block).to have_received(:call).with("Second chunk")

        yielder.call("Final chunk\n")
        expect(mocked_block).to have_received(:call).with("Final chunk")
      end

      response = http.get(path, stream: true)
      response.raise_for_status
      response.each_line(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")
      expect(mocked_block).to have_received(:call).with("Final chunk")
    end

    # That's why it shouldn't be used in streamed requests
    # Instead, we depend on the each block to consume the body and raise an error if the status code is not 200
    it "can catch errors by calling raise_for_status, but you can't read the body" do
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("Bundle Required")
      end

      response = http.get(path, stream: true)

      expect do
        response.raise_for_status
      end.to(raise_error do |error|
        expect(error.response.status).to eq(410)
      end)

      clear_stream_mocks
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        sleep(0.1)
        yielder.call("Second chunk")
        yielder.call("Final chunk")
      end

      response = http.get(path, stream: true)
      chunks = []

      response.each do |chunk|
        chunks << chunk
      end

      expect(chunks).to eq(["First chunk", "Second chunk", "Final chunk"])
    end
  end

  describe ".status" do
    it "is not blocking" do
      mocked_block = mock_block

      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        expect(mocked_block).to have_received(:call).with("First chunk")

        yielder.call("Second chunk")
        expect(mocked_block).to have_received(:call).with("Second chunk")

        yielder.call("Final chunk")
        expect(mocked_block).to have_received(:call).with("Final chunk")
      end

      response = http.get(path, stream: true)
      expect(response.status).to eq(200)
      response.each(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")
      expect(mocked_block).to have_received(:call).with("Final chunk")
    end

    it "is not blocking when called inside each" do
      mocked_block = mock_block
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        expect(mocked_block).to have_received(:call).with("First chunk")
        yielder.call("Second chunk")
        expect(mocked_block).to have_received(:call).with("Second chunk")
        yielder.call("Final chunk")
        expect(mocked_block).to have_received(:call).with("Final chunk")
      end

      response = http.get(path, stream: true)
      response.each do |chunk|
        expect(response.status).to eq(200)
        mocked_block.call(chunk)
      end
    end
  end

  it "handles erroneous and then successful streaming responses" do
    mock_streaming_response(url, 410) do |yielder|
      yielder.call("Bundle Required")
    end

    response = http.get(path, stream: true)
    body = +""
    expect do
      response.each do |chunk|
        body << chunk
      end
    end.to(raise_error do |error|
      expect(error.response.status).to eq(410)
      expect(body).to eq("Bundle Required")
      # The body is empty after calling each.
      expect(error.response.to_s).to eq("")
    end)

    mock_streaming_response(url, 200) do |yielder|
      yielder.call("First chunk")
      yielder.call("Second chunk")
      yielder.call("Final chunk")
    end

    response = http.get(path, stream: true)
    chunks = []
    response.each do |chunk|
      chunks << chunk
    end
    expect(chunks).to eq(["First chunk", "Second chunk", "Final chunk"])
  end

  describe "each_line" do
    it "yields the whole body if there's no new lines" do
      mocked_block = mock_block
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        sleep(0.2)
        yielder.call("Second chunk")
      end

      response = http.get(path, stream: true)
      response.each_line(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunkSecond chunk")
    end

    # Weird behavior
    it "doesn't yield body with no new lines on error and the error has no body" do
      mocked_block = mock_block
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("Bundle Required")
      end

      response = http.get(path, stream: true)
      expect do
        response.each_line(&mocked_block.block)
      end.to(raise_error do |error|
        expect(error.response.status).to eq(410)
        expect(error.response.body.to_s).to eq("")
      end)
      expect(mocked_block).not_to have_received(:call)
    end

    # Weird behavior
    it "doesn't yield last chunk if it doesn't end with a new line" do
      mocked_block = mock_block
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("First chunk\n")
        yielder.call("Second chunk")
      end

      response = http.get(path, stream: true)
      expect do
        response.each_line(&mocked_block.block)
      end.to(raise_error do |error|
        expect(error.response.status).to eq(410)
        expect(error.response.body.to_s).to eq("")
      end)
      expect(mocked_block).to have_received(:call).once.with("First chunk")
    end
  end

  describe ".body" do
    it "always empty when :stream plugin is used" do
      status_codes = [200, 410, 500]
      status_codes.each do |status_code|
        mock_streaming_response(url, status_code) do |yielder|
          yielder.call("Chunk")
        end

        response = http.get(path, stream: true)
        expect(response.body.to_s).to eq("")
      end
    end

    it "implements wrong == operator" do
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("Chunk")
      end

      response = http.get(path, stream: true)
      expect(response.body).to eq("Chunk")
      expect(response.body).to eq("Wrong Chunk")
      expect(response.body).to eq("No sense")
    end
  end

  describe "each" do
    it "yields chunks one by one" do
      mocked_block = mock_block
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        yielder.call("Second chunk")
      end

      response = http.get(path, stream: true)
      response.each(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")
    end

    # Always consume the response body using the each block, even on error.
    # Note: If the response has an error status code, an exception is raised only after all chunks have been yielded.
    # This ensures that all available chunks are processed before the error is reported.
    it "yields chunks one by one on error" do
      mocked_block = mock_block
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("First chunk")
        yielder.call("Second chunk")
      end

      response = http.get(path, stream: true)
      expect do
        response.each(&mocked_block.block)
      end.to(raise_error do |error|
        expect(error.response.status).to eq(410)
        expect(error.response.body.to_s).to eq("")
      end)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")
    end

    it "supports multiple calls" do
      mocked_block = mock_block
      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        yielder.call("Second chunk")
      end

      http.get(path, stream: true)
      sleep 0.5
      # No request is made until each is called
      expect(mocked_block).not_to have_received(:call)

      mock_streaming_response(url, 200) do |yielder|
        yielder.call("Third chunk")
        yielder.call("Fourth chunk")
      end

      response = http.get(path, stream: true)
      response.each(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")

      mocked_block = mock_block
      # Each yields the chunks of the request it made
      # It doesn't make another request when called again
      response.each(&mocked_block.block)
      expect(mocked_block).not_to have_received(:call)

      # You need to make a new request explicitly
      response = http.get(path, stream: true)
      response.each(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("Third chunk")
      expect(mocked_block).to have_received(:call).with("Fourth chunk")
    end

    it "handle errors" do
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("First chunk")
        raise "Fake error"
      end

      mocked_block = mock_block
      response = http.get(path, stream: true)
      expect do
        response.each(&mocked_block.block)
      end.to(raise_error do |error|
        expect(error.message).to eq("Fake error")
      end)
      expect(mocked_block).to have_received(:call).once
      expect(mocked_block).to have_received(:call).with("First chunk")
    end
  end

  describe "Component streaming concurrency" do
    def run_stream(controller, template: "ignored", **options)
      Sync do |parent|
        parent.async { controller.stream_view_containing_react_components(template: template, **options) }
        yield(parent)
      end
    end

    def build_mocked_response(headers)
      mocked_response = instance_double(ActionController::Live::Response)
      mocked_stream = instance_double(ActionController::Live::Buffer)
      response_headers = ActionDispatch::Response::Headers.new
      headers.each { |key, value| response_headers[key] = value }
      allow(mocked_response).to receive_messages(stream: mocked_stream, headers: response_headers)
      allow(mocked_stream).to receive(:write)
      allow(mocked_stream).to receive(:close)
      allow(mocked_stream).to receive(:closed?).and_return(false)
      [mocked_response, mocked_stream, response_headers]
    end

    def build_mocked_request(accept_encoding)
      mocked_request = instance_double(ActionDispatch::Request)
      allow(mocked_request).to receive(:get_header).and_return(nil)
      allow(mocked_request).to receive(:get_header).with("HTTP_ACCEPT_ENCODING").and_return(accept_encoding)
      mocked_request
    end

    def setup_stream_test(component_count: 2, headers: {}, accept_encoding: nil)
      component_queues = Array.new(component_count) { Async::Queue.new }
      controller = StreamController.new(component_queues: component_queues)

      mocked_response, mocked_stream, mocked_headers = build_mocked_response(headers)
      mocked_request = build_mocked_request(accept_encoding)
      allow(controller).to receive_messages(response: mocked_response, request: mocked_request)

      [component_queues, controller, mocked_stream, mocked_headers, mocked_request]
    end

    it "streams components concurrently" do
      queues, controller, stream, _headers, _request = setup_stream_test

      run_stream(controller) do |_parent|
        queues[1].enqueue("B1")
        sleep 0.05
        expect(stream).to have_received(:write).with("B1")

        queues[0].enqueue("A1")
        sleep 0.05
        expect(stream).to have_received(:write).with("A1")

        queues[1].enqueue("B2")
        queues[1].close
        sleep 0.05

        queues[0].enqueue("A2")
        queues[0].close
        sleep 0.1
      end
    end

    it "maintains per-component ordering" do
      queues, controller, stream, _headers, _request = setup_stream_test

      run_stream(controller) do |_parent|
        queues[0].enqueue("X1")
        queues[0].enqueue("X2")
        queues[0].enqueue("X3")
        queues[0].close

        queues[1].enqueue("Y1")
        queues[1].enqueue("Y2")
        queues[1].close

        sleep 0.2
      end

      # Verify all chunks were written
      expect(stream).to have_received(:write).with("X1")
      expect(stream).to have_received(:write).with("X2")
      expect(stream).to have_received(:write).with("X3")
      expect(stream).to have_received(:write).with("Y1")
      expect(stream).to have_received(:write).with("Y2")
    end

    it "compresses stream output with gzip when enabled and accepted by client" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip, deflate"
      )
      compressed_chunks = []
      allow(stream).to receive(:write) do |chunk|
        compressed_chunks << chunk
      end

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      compressed_body = compressed_chunks.join
      decompressed_body = Zlib::GzipReader.new(StringIO.new(compressed_body)).read

      expect(decompressed_body).to eq("TEMPLATEChunk1")
      expect(headers["Content-Encoding"]).to eq("gzip")
      expect(headers["Vary"]).to eq("Accept-Encoding")
      expect(stream).to have_received(:close)
    end

    it "preserves existing Vary directives when enabling gzip streaming" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        headers: { "Vary" => "Origin" },
        accept_encoding: "gzip"
      )
      compressed_chunks = []
      allow(stream).to receive(:write) do |chunk|
        compressed_chunks << chunk
      end

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      decompressed_body = Zlib::GzipReader.new(StringIO.new(compressed_chunks.join)).read
      expect(decompressed_body).to eq("TEMPLATEChunk1")
      expect(headers["Vary"]).to eq("Origin, Accept-Encoding")
    end

    it "keeps plain streaming when client does not accept gzip" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "br"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "keeps plain streaming when identity quality beats gzip" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip;q=0.3, identity;q=0.9"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "compresses stream output when wildcard quality beats identity" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "br;q=1.0, *;q=0.8, identity;q=0.5"
      )
      compressed_chunks = []
      allow(stream).to receive(:write) do |chunk|
        compressed_chunks << chunk
      end

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      decompressed_body = Zlib::GzipReader.new(StringIO.new(compressed_chunks.join)).read
      expect(decompressed_body).to eq("TEMPLATEChunk1")
      expect(headers["Content-Encoding"]).to eq("gzip")
    end

    it "keeps plain streaming when Accept-Encoding is malformed" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip;q=invalid"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "keeps plain streaming when Accept-Encoding has q without a value" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip;q"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "compresses when malformed q applies to a different token" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip;q=1, deflate;q=bad"
      )
      compressed_chunks = []
      allow(stream).to receive(:write) do |chunk|
        compressed_chunks << chunk
      end

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      decompressed_body = Zlib::GzipReader.new(StringIO.new(compressed_chunks.join)).read
      expect(decompressed_body).to eq("TEMPLATEChunk1")
      expect(headers["Content-Encoding"]).to eq("gzip")
    end

    it "keeps plain streaming when gzip is explicitly excluded" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        accept_encoding: "gzip;q=0, identity;q=1"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "keeps plain streaming when response already has non-identity encodings" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        headers: { "Content-Encoding" => "deflate, gzip" },
        accept_encoding: "gzip"
      )

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:write).with("Chunk1")
      expect(headers["Content-Encoding"]).to eq("deflate, gzip")
    end

    it "compresses when response has only identity encodings" do
      queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 1,
        headers: { "Content-Encoding" => "identity, identity" },
        accept_encoding: "gzip"
      )
      compressed_chunks = []
      allow(stream).to receive(:write) do |chunk|
        compressed_chunks << chunk
      end

      run_stream(controller, compress: true) do |_parent|
        queues[0].enqueue("Chunk1")
        queues[0].close
      end

      decompressed_body = Zlib::GzipReader.new(StringIO.new(compressed_chunks.join)).read
      expect(decompressed_body).to eq("TEMPLATEChunk1")
      expect(headers["Content-Encoding"]).to eq("gzip")
    end

    it "raises if compression is requested without closing the stream" do
      _queues, controller, _stream, _headers, _request = setup_stream_test(
        component_count: 0,
        accept_encoding: "gzip"
      )

      expect do
        controller.stream_view_containing_react_components(
          template: "ignored",
          compress: true,
          close_stream_at_end: false
        )
      end.to raise_error(ArgumentError, /compress: true requires close_stream_at_end: true/)
    end

    it "allows compress option with open stream when gzip is not enabled" do
      _queues, controller, stream, headers, _request = setup_stream_test(
        component_count: 0,
        accept_encoding: "br"
      )

      expect do
        controller.stream_view_containing_react_components(
          template: "ignored",
          compress: true,
          close_stream_at_end: false
        )
      end.not_to raise_error

      expect(stream).not_to have_received(:close)
      expect(headers["Content-Encoding"]).to be_nil
    end

    it "does not set gzip headers when template rendering fails before commit" do
      _queues, controller, _stream, headers, _request = setup_stream_test(
        component_count: 0,
        accept_encoding: "gzip"
      )
      allow(controller).to receive(:render_to_string).and_raise(StandardError, "render failed")

      expect do
        controller.stream_view_containing_react_components(template: "ignored", compress: true)
      end.to raise_error(StandardError, "render failed")

      expect(headers["Content-Encoding"]).to be_nil
      expect(headers["Vary"]).to be_nil
    end

    it "handles empty component list" do
      _queues, controller, stream, _headers, _request = setup_stream_test(component_count: 0)

      run_stream(controller) do |_parent|
        sleep 0.1
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:close)
    end

    it "handles single component" do
      queues, controller, stream, _headers, _request = setup_stream_test(component_count: 1)

      run_stream(controller) do |_parent|
        queues[0].enqueue("Single1")
        queues[0].enqueue("Single2")
        queues[0].close

        sleep 0.1
      end

      expect(stream).to have_received(:write).with("Single1")
      expect(stream).to have_received(:write).with("Single2")
    end

    it "applies backpressure with slow writer" do
      queues, controller, stream, _headers, _request = setup_stream_test(component_count: 1)

      write_timestamps = []
      allow(stream).to receive(:write) do |_data|
        write_timestamps << Process.clock_gettime(Process::CLOCK_MONOTONIC)
        sleep 0.05
      end

      run_stream(controller) do |_parent|
        5.times { |i| queues[0].enqueue("Chunk#{i}") }
        queues[0].close

        sleep 1
      end

      expect(write_timestamps.length).to be >= 2
      gaps = write_timestamps.each_cons(2).map { |a, b| b - a }
      expect(gaps.all? { |gap| gap >= 0.04 }).to be true
    end

    describe "client disconnect handling" do
      it "stops writing on IOError" do
        queues, controller, stream, _headers, _request = setup_stream_test(component_count: 1)

        written_chunks = []
        write_count = 0

        allow(stream).to receive(:write) do |chunk|
          write_count += 1
          raise IOError, "client disconnected" if write_count == 3

          written_chunks << chunk
        end

        run_stream(controller) do |_parent|
          queues[0].enqueue("Chunk1")
          sleep 0.05
          queues[0].enqueue("Chunk2")
          sleep 0.05
          queues[0].enqueue("Chunk3")
          sleep 0.05
          queues[0].enqueue("Chunk4")
          queues[0].close
          sleep 0.1
        end

        # Write 1: TEMPLATE, Write 2: Chunk1, Write 3: Chunk2 (raises IOError)
        expect(written_chunks).to eq(%w[TEMPLATE Chunk1])
      end

      it "stops writing on Errno::EPIPE" do
        queues, controller, stream, _headers, _request = setup_stream_test(component_count: 1)

        written_chunks = []
        write_count = 0

        allow(stream).to receive(:write) do |chunk|
          write_count += 1
          raise Errno::EPIPE, "broken pipe" if write_count == 3

          written_chunks << chunk
        end

        run_stream(controller) do |_parent|
          queues[0].enqueue("Chunk1")
          sleep 0.05
          queues[0].enqueue("Chunk2")
          sleep 0.05
          queues[0].enqueue("Chunk3")
          queues[0].close
          sleep 0.1
        end

        expect(written_chunks).to eq(%w[TEMPLATE Chunk1])
      end

      it "suppresses gzip footer close errors after client disconnect" do
        queues, controller, stream, _headers, _request = setup_stream_test(
          component_count: 1,
          accept_encoding: "gzip"
        )

        write_count = 0
        allow(stream).to receive(:write) do |_chunk|
          write_count += 1
          raise Errno::EPIPE, "broken pipe" if write_count >= 3
        end

        expect do
          run_stream(controller, compress: true) do |_parent|
            queues[0].enqueue("Chunk1")
            queues[0].enqueue("Chunk2")
            queues[0].close
          end
        end.not_to raise_error
      end
    end

    describe "writer task cleanup" do
      it "preserves the original stream exception when waiting on the writer task also fails" do
        controller = StreamController.new(component_queues: [])

        expect do
          Sync do |parent|
            writing_task = parent.async { raise Zlib::Error, "gzip flush failed" }

            begin
              raise StandardError, "producer failed"
            rescue StandardError => e
              controller.send(:wait_for_writing_task, writing_task, pending_exception: e)
              raise
            end
          end
        end.to raise_error(StandardError, "producer failed")
      end
    end

    describe ReactOnRailsPro::Stream::GzipOutputStream do
      it "tracks closed state" do
        stream = StringIO.new
        gzip_stream = described_class.new(stream)

        expect(gzip_stream.closed?).to be(false)

        gzip_stream.close

        expect(gzip_stream.closed?).to be(true)
      end

      it "raises on write after close" do
        stream = StringIO.new
        gzip_stream = described_class.new(stream)

        gzip_stream.close

        expect do
          gzip_stream.write("late chunk")
        end.to raise_error(IOError, /closed GzipOutputStream/)
      end
    end
  end
end
