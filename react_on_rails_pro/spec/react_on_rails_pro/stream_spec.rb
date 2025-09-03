# frozen_string_literal: true

require "async"
require "async/queue"
require_relative "spec_helper"

# Test helper classes for streaming specs
class TestStream
  def initialize(chunks_with_delays:, raise_after: nil)
    @chunks_with_delays = chunks_with_delays
    @raise_after = raise_after
  end

  def each_chunk
    return enum_for(:each_chunk) unless block_given?

    count = 0
    @chunks_with_delays.each do |(delay, data)|
      begin
        require "async"
        task = Async::Task.current
        task ? task.sleep(delay) : sleep(delay)
      rescue StandardError
        sleep(delay)
      end
      yield data
      count += 1
      raise "Fake error" if @raise_after && count >= @raise_after
    end
  end
end

class TestResponseStream
  attr_reader :writes

  def initialize
    @writes = []
    @closed = false
  end

  def write(data)
    @writes << data
  end

  def close
    @closed = true
  end

  def closed?
    @closed
  end
end

class SlowResponseStream < TestResponseStream
  attr_reader :timestamps

  def initialize(delay: 0.05)
    super()
    @delay = delay
    @timestamps = []
  end

  def write(data)
    sleep(@delay)
    @timestamps << Process.clock_gettime(Process::CLOCK_MONOTONIC)
    super
  end
end

ResponseStruct = Struct.new(:stream)

class SimpleTestController
  include ReactOnRailsPro::Stream

  # @param initial_response [String] The initial response to be streamed
  # @param component_queues [Array<Async::Queue>] The queues for each component
  def initialize(initial_response: "Template", component_queues: [])
    @initial_response = initial_response
    @component_queues = component_queues
  end

  attr_reader :response

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

class TestController
  include ReactOnRailsPro::Stream

  attr_reader :response

  def initialize(streams)
    @streams = streams
    @response = ResponseStruct.new(TestResponseStream.new)
  end

  def render_to_string(**_opts)
    @rorp_rendering_fibers ||= []
    initial_chunks = []
    @streams.each do |s|
      fiber = Fiber.new do
        s.each_chunk do |chunk|
          Fiber.yield chunk
        end
      end
      initial_chunks << fiber.resume
      @rorp_rendering_fibers << fiber
    end
    ["TEMPLATE\n", *initial_chunks].join
  end
end

class SlowWriterController < TestController
  def initialize(streams)
    super(streams)
    @response = ResponseStruct.new(SlowResponseStream.new(delay: 0.05))
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

  it "streams components concurrently" do
    original_concurrent_stream_drain = ReactOnRailsPro.configuration.concurrent_stream_drain
    ReactOnRailsPro.configuration.concurrent_stream_drain = true
    component_queues = [Async::Queue.new, Async::Queue.new]
    controller = SimpleTestController.new(initial_response: "Template", component_queues: component_queues)

    mocked_response = instance_double(ActionController::Live::Response)
    mocked_stream = instance_double(ActionController::Live::Buffer)
    allow(mocked_response).to receive(:stream).and_return(mocked_stream)
    allow(mocked_stream).to receive(:write)
    allow(mocked_stream).to receive(:close)
    allow(controller).to receive(:response).and_return(mocked_response)

    Sync do |parent|
      parent.async do
        controller.stream_view_containing_react_components(template: "ignored")
      end

      expect(mocked_stream).to have_received(:write).once.with("Template")

      component_queues[1].enqueue("Component 2")
      sleep 0.1 # Wait for the writer to dequeue the chunk
      expect(mocked_stream).to have_received(:write).with("Component 2")

      component_queues[0].enqueue("Component 1")
      sleep 0.1
      expect(mocked_stream).to have_received(:write).with("Component 1")

      component_queues[0].enqueue("Component 1-1")
      sleep 0.1
      expect(mocked_stream).to have_received(:write).with("Component 1-1")

      component_queues[1].enqueue("Component 2-1")
      component_queues[0].enqueue("Component 1-2")

      sleep 0.1
      expect(mocked_stream).to have_received(:write).with("Component 2-1")
      expect(mocked_stream).to have_received(:write).with("Component 1-2")

      component_queues.each(&:close)
    ensure
      ReactOnRailsPro.configuration.concurrent_stream_drain = original_concurrent_stream_drain
    end
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

  describe "Controller streaming (concurrent vs sequential)" do
    let(:a_stream) { TestStream.new(chunks_with_delays: [[0.30, "A1\n"], [0.90, "A2\n"]]) }
    let(:b_stream) { TestStream.new(chunks_with_delays: [[0.10, "B1\n"], [0.10, "B2\n"], [0.20, "B3\n"]]) }

    def run_and_collect(streams:, concurrent:)
      original = ReactOnRailsPro.configuration.concurrent_stream_drain
      ReactOnRailsPro.configuration.concurrent_stream_drain = concurrent
      controller = TestController.new(streams)
      controller.stream_view_containing_react_components(template: "ignored")
      [controller.response.stream.writes, controller.response.stream.closed?]
    ensure
      ReactOnRailsPro.configuration.concurrent_stream_drain = original
    end

    it "gates by config (sequential vs concurrent)" do
      writes_seq, closed_seq = run_and_collect(streams: [a_stream, b_stream], concurrent: false)
      writes_conc, closed_conc = run_and_collect(streams: [a_stream, b_stream], concurrent: true)

      expect(writes_seq.first).to start_with("TEMPLATE")
      expect(writes_conc.first).to start_with("TEMPLATE")

      joined_seq = writes_seq.drop(1).join
      joined_conc = writes_conc.drop(1).join

      expect(joined_seq).to match(/A2.*B2.*B3/m)
      expect(joined_conc).to match(/B2.*A2/m)

      expect(closed_seq).to be true
      expect(closed_conc).to be true
    end

    it "preserves per-component order" do
      multi_a = TestStream.new(chunks_with_delays: [[0.05, "X1\n"], [0.05, "X2\n"], [0.05, "X3\n"]])
      multi_b = TestStream.new(chunks_with_delays: [[0.01, "Y1\n"], [0.02, "Y2\n"]])
      writes, = run_and_collect(streams: [multi_a, multi_b], concurrent: true)
      joined = writes.join
      # X1 is inline in template; ensure X2 before X3 in remaining output.
      expect(joined).to match(/X2.*X3/m)
    end

    it "handles zero fibers" do
      writes, closed = run_and_collect(streams: [], concurrent: true)
      expect(writes).to eq(["TEMPLATE\n"])
      expect(closed).to be true
    end

    it "handles one fiber same as before" do
      single = TestStream.new(chunks_with_delays: [[0.05, "S1\n"], [0.05, "S2\n"]])
      writes_seq, = run_and_collect(streams: [single], concurrent: false)
      writes_conc, = run_and_collect(streams: [single], concurrent: true)
      expect(writes_seq.join).to include("S2\n")
      expect(writes_conc.join).to include("S2\n")
    end

    it "fails the request when a producer errors", :aggregate_failures do
      erring = TestStream.new(chunks_with_delays: [[0.01, "E1\n"]], raise_after: 1)
      ok     = TestStream.new(chunks_with_delays: [[0.01, "O1\n"], [0.02, "O2\n"]])

      # The `async` gem logs unhandled task exceptions to stderr, which is
      # expected in this test. We capture the output to keep the test run clean.
      expect do
        expect do
          run_and_collect(streams: [erring, ok], concurrent: true)
        end.to raise_error(RuntimeError, "Fake error")
      end.to output.to_stderr
    end

    it "applies backpressure: writer delay spaces out queued writes" do
      # Force capacity=1 via stubbing Async::Semaphore.new for this example.
      allow(Async::Semaphore).to receive(:new).and_wrap_original do |m, _permits|
        m.call(1)
      end

      # Stream emits three chunks quickly; first is inline in template, next two go through queue.
      fast = TestStream.new(chunks_with_delays: [[0.0, "C1\n"], [0.0, "C2\n"], [0.0, "C3\n"]])
      original = ReactOnRailsPro.configuration.concurrent_stream_drain
      ReactOnRailsPro.configuration.concurrent_stream_drain = true

      controller = SlowWriterController.new([fast])
      controller.stream_view_containing_react_components(template: "ignored")
      timestamps = controller.response.stream.timestamps

      # We expect at least two writes via writer (C2, C3). With capacity=1 and a 50ms write delay,
      # the gap between the two writer writes should be >= ~50ms.
      expect(timestamps.length).to be >= 2
      gap = timestamps[1] - timestamps[0]
      expect(gap).to be >= 0.045
    ensure
      ReactOnRailsPro.configuration.concurrent_stream_drain = original
    end
  end
end
