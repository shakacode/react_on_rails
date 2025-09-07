# frozen_string_literal: true

require "async"
require "async/queue"
require_relative "spec_helper"

class StreamController
  include ReactOnRailsPro::Stream

  attr_reader :response

  def initialize(component_queues:, initial_response: "TEMPLATE")
    @component_queues = component_queues
    @initial_response = initial_response
  end

  def render_to_string(**_opts)
    @rorp_rendering_fibers = @component_queues.map do |queue|
      Fiber.new do
        loop do
          chunk = queue.dequeue
          break if chunk.nil?

          Fiber.yield chunk
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
    def with_concurrent_stream_drain(enabled)
      original = ReactOnRailsPro.configuration.concurrent_stream_drain
      ReactOnRailsPro.configuration.concurrent_stream_drain = enabled
      yield
    ensure
      ReactOnRailsPro.configuration.concurrent_stream_drain = original
    end

    def run_stream(controller, template: "ignored")
      Sync do |parent|
        parent.async { controller.stream_view_containing_react_components(template: template) }
        yield(parent)
      end
    end

    def setup_stream_test(component_count: 2)
      component_queues = Array.new(component_count) { Async::Queue.new }
      controller = StreamController.new(component_queues: component_queues)

      mocked_response = instance_double(ActionController::Live::Response)
      mocked_stream = instance_double(ActionController::Live::Buffer)
      allow(mocked_response).to receive(:stream).and_return(mocked_stream)
      allow(mocked_stream).to receive(:write)
      allow(mocked_stream).to receive(:close)
      allow(controller).to receive(:response).and_return(mocked_response)

      [component_queues, controller, mocked_stream]
    end

    it "processes components concurrently vs sequentially" do
      seq_queues, seq_controller, seq_stream = setup_stream_test

      with_concurrent_stream_drain(false) do
        run_stream(seq_controller) do |_parent|
          seq_queues[0].enqueue("A1")
          seq_queues[0].enqueue("A2")
          seq_queues[0].close

          seq_queues[1].enqueue("B1")
          seq_queues[1].enqueue("B2")
          seq_queues[1].close

          sleep 0.1
        end
      end

      # Verify sequential behavior: all A chunks processed before B chunks start
      expect(seq_stream).to have_received(:write).with("TEMPLATE")
      expect(seq_stream).to have_received(:write).with("A1") 
      expect(seq_stream).to have_received(:write).with("A2")
      expect(seq_stream).to have_received(:write).with("B1")
      expect(seq_stream).to have_received(:write).with("B2")

      conc_queues, conc_controller, conc_stream = setup_stream_test

      with_concurrent_stream_drain(true) do
        run_stream(conc_controller) do |_parent|
          conc_queues[1].enqueue("B1")
          sleep 0.05
          expect(conc_stream).to have_received(:write).with("B1")

          conc_queues[0].enqueue("A1")
          sleep 0.05
          expect(conc_stream).to have_received(:write).with("A1")

          conc_queues[1].enqueue("B2")
          conc_queues[1].close
          sleep 0.05

          conc_queues[0].enqueue("A2")
          conc_queues[0].close
          sleep 0.1
        end
      end

    # Verify concurrent behavior: components can process interleaved
    expect(conc_stream).to have_received(:write).with("B1")
    expect(conc_stream).to have_received(:write).with("A1") 
    expect(conc_stream).to have_received(:write).with("B2")
    expect(conc_stream).to have_received(:write).with("A2")
    end

    it "maintains per-component ordering" do
      queues, controller, stream = setup_stream_test

      with_concurrent_stream_drain(true) do
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
      end

      # Verify all chunks were written
      expect(stream).to have_received(:write).with("X1")
      expect(stream).to have_received(:write).with("X2")
      expect(stream).to have_received(:write).with("X3")
      expect(stream).to have_received(:write).with("Y1")
      expect(stream).to have_received(:write).with("Y2")
    end

    it "handles empty component list" do
      queues, controller, stream = setup_stream_test(component_count: 0)

      with_concurrent_stream_drain(true) do
        run_stream(controller) do |_parent|
          sleep 0.1
        end
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:close)
    end

    it "handles single component" do
      queues, controller, stream = setup_stream_test(component_count: 1)

      with_concurrent_stream_drain(true) do
        run_stream(controller) do |_parent|
          queues[0].enqueue("Single1")
          queues[0].enqueue("Single2")
          queues[0].close

          sleep 0.1
        end
      end

      expect(stream).to have_received(:write).with("Single1")
      expect(stream).to have_received(:write).with("Single2")
    end

    it "applies backpressure with slow writer" do
      queues, controller, stream = setup_stream_test(component_count: 1)

      write_timestamps = []
      allow(stream).to receive(:write) do |data|
        write_timestamps << Process.clock_gettime(Process::CLOCK_MONOTONIC)
        sleep 0.05
      end

      with_concurrent_stream_drain(true) do
        run_stream(controller) do |_parent|
          5.times { |i| queues[0].enqueue("Chunk#{i}") }
          queues[0].close

          sleep 1
        end
      end

      expect(write_timestamps.length).to be >= 2
      gaps = write_timestamps.each_cons(2).map { |a, b| b - a }
      expect(gaps.all? { |gap| gap >= 0.04 }).to be true
    end
  end
end
