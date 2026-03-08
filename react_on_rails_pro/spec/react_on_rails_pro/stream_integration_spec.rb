# frozen_string_literal: true

# Integration tests for streaming client disconnect handling.
#
# Unlike the unit tests in stream_spec.rb (which mock stream.write/close/closed?),
# these tests use a real Queue-backed buffer with a real reader thread that consumes
# chunks and closes the buffer to simulate client disconnect. The IOError arises
# naturally from writing to a closed buffer — the same mechanism as production
# (where Puma detects client disconnect and closes the ActionController::Live::Buffer).
#
# The full streaming pipeline is exercised:
#   Producer fibers → LimitedQueue (backpressure) → writing_task fiber → Buffer (Queue) → reader thread

require "async"
require "async/queue"
require "async/variable"
require "timeout"
require_relative "spec_helper"

# Replicates ActionController::Live::Buffer behavior with real Queue-based IO.
# Thread-safe: writer (fiber) pushes, reader (thread) pops.
class TestStreamBuffer
  def initialize
    @buf = Queue.new
    @closed = false
  end

  def write(string)
    raise IOError, "closed stream" if @closed

    @buf.push(string)
  end

  def each
    while (str = @buf.pop)
      yield str
    end
  end

  def close
    return if @closed

    @closed = true
    @buf.push(nil)
  end

  def closed?
    @closed
  end
end

# Minimal response wrapper satisfying the Stream concern's interface.
class TestLiveResponse
  attr_reader :stream
  attr_accessor :content_type

  def initialize(stream)
    @stream = stream
  end
end

# Controller that includes the real Stream concern with configurable components.
# Each component produces a fixed number of chunks via barrier tasks.
class IntegrationStreamController
  include ReactOnRailsPro::Stream

  def initialize(response:, component_configs:)
    @live_response = response
    @component_configs = component_configs
  end

  def response
    @live_response
  end

  def render_to_string(**_opts)
    @component_configs.each do |config|
      chunk_count = config[:chunks]
      component_id = config[:id]
      @async_barrier.async do
        chunk_count.times do |i|
          @main_output_queue.enqueue("#{component_id}_chunk_#{i}\n")
        end
      end
    end
    "TEMPLATE\n"
  end
end

RSpec.describe "Streaming client disconnect integration" do
  before do
    allow(ReactOnRails.configuration).to receive(:logging_on_server).and_return(false)
  end

  # Creates a streaming controller, reader thread, and runs the stream.
  # The reader thread consumes chunks from the buffer and closes it after
  # `disconnect_after` chunks to simulate client disconnect.
  #
  # @param component_configs [Array<Hash>] e.g. [{ id: "A", chunks: 5 }]
  # @param disconnect_after [Integer] close the buffer after this many chunks
  # @param buffer_size [Integer] LimitedQueue size (controls backpressure)
  # @param timeout_seconds [Integer] deadlock detection timeout
  # @return [Hash] { chunks_received:, reader_thread:, error: }
  def run_disconnect_test(component_configs:, disconnect_after:, buffer_size: 5, timeout_seconds: 10)
    allow(ReactOnRailsPro.configuration)
      .to receive(:concurrent_component_streaming_buffer_size).and_return(buffer_size)

    buffer = TestStreamBuffer.new
    response = TestLiveResponse.new(buffer)
    controller = IntegrationStreamController.new(
      response: response,
      component_configs: component_configs
    )

    chunks_received = []
    reader_error = nil

    # Reader thread simulates Puma's response body consumer.
    # It reads chunks from the buffer and disconnects after N chunks.
    reader_thread = Thread.new do
      buffer.each do |chunk|
        chunks_received << chunk
        if chunks_received.size >= disconnect_after
          buffer.close
          break
        end
      end
    rescue StandardError => e
      reader_error = e
    end

    stream_error = nil
    Timeout.timeout(timeout_seconds) do
      controller.stream_view_containing_react_components(template: "test")
    rescue StandardError => e
      stream_error = e
    end

    reader_thread.join(timeout_seconds)

    { chunks_received: chunks_received, stream_error: stream_error, reader_error: reader_error }
  end

  # Runs a successful (no-disconnect) streaming operation to verify the server
  # can still process requests after a disconnect.
  def run_healthy_stream(component_configs:, buffer_size: 5, timeout_seconds: 10)
    allow(ReactOnRailsPro.configuration)
      .to receive(:concurrent_component_streaming_buffer_size).and_return(buffer_size)

    buffer = TestStreamBuffer.new
    response = TestLiveResponse.new(buffer)
    controller = IntegrationStreamController.new(
      response: response,
      component_configs: component_configs
    )

    chunks_received = []

    reader_thread = Thread.new do
      buffer.each do |chunk|
        chunks_received << chunk
      end
    end

    Timeout.timeout(timeout_seconds) do
      controller.stream_view_containing_react_components(template: "test")
    end

    reader_thread.join(timeout_seconds)
    chunks_received
  end

  describe "small response (1 component, 5 chunks)" do
    let(:components) { [{ id: "A", chunks: 5 }] }

    it "handles client disconnect after 2 chunks without deadlock" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 2
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 2
    end

    it "handles client disconnect after template-only (1 chunk) without deadlock" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 1
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 1
      expect(result[:chunks_received].first).to eq("TEMPLATE\n")
    end

    it "server can process another request after disconnect" do
      # First: disconnect mid-stream
      run_disconnect_test(
        component_configs: components,
        disconnect_after: 2
      )

      # Second: full successful stream — proves no leaked state
      chunks = run_healthy_stream(
        component_configs: [{ id: "B", chunks: 3 }]
      )

      # Template + 3 component chunks
      expect(chunks.size).to eq(4)
      expect(chunks.first).to eq("TEMPLATE\n")
    end
  end

  describe "medium response (2 components, 50 chunks each)" do
    let(:components) { [{ id: "A", chunks: 50 }, { id: "B", chunks: 50 }] }

    it "handles client disconnect at chunk 30 without deadlock" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 30
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 30
      # Should be much less than total (1 template + 100 component chunks)
      expect(result[:chunks_received].size).to be < 101
    end

    it "handles disconnect with tight backpressure (buffer_size=1)" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 10,
        buffer_size: 1
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 10
    end

    it "server recovers and handles a full request after disconnect" do
      run_disconnect_test(
        component_configs: components,
        disconnect_after: 15,
        buffer_size: 1
      )

      chunks = run_healthy_stream(
        component_configs: [{ id: "C", chunks: 10 }],
        buffer_size: 1
      )

      expect(chunks.size).to eq(11)
    end
  end

  describe "large response (3 components, 1000 chunks each)" do
    let(:components) do
      [
        { id: "A", chunks: 1000 },
        { id: "B", chunks: 1000 },
        { id: "C", chunks: 1000 }
      ]
    end

    it "handles early disconnect (chunk 10) with buffer_size=1 without deadlock" do
      # This is the critical deadlock scenario from Bug #2543:
      # - 3 producers generating 1000 chunks each
      # - Buffer size 1 means producers block on enqueue immediately
      # - Client disconnects very early (after 10 chunks)
      # - All 3 producers are likely blocked on enqueue when disconnect happens
      # - Without the fix: permanent deadlock (barrier.wait hangs forever)
      # - With the fix: writing_task's ensure stops barrier, unblocking producers
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 10,
        buffer_size: 1
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 10
      # Should be much less than the total 3001 chunks
      expect(result[:chunks_received].size).to be < 100
    end

    it "handles mid-stream disconnect with buffer_size=1 without deadlock" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 500,
        buffer_size: 1
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 500
    end

    it "handles disconnect near end of stream without deadlock" do
      result = run_disconnect_test(
        component_configs: components,
        disconnect_after: 2900,
        buffer_size: 1
      )

      expect(result[:stream_error]).to be_nil
      expect(result[:reader_error]).to be_nil
      expect(result[:chunks_received].size).to be >= 2900
    end

    it "completes full stream without disconnect (baseline)" do
      # Verify the test infrastructure works for a full successful stream
      chunks = run_healthy_stream(
        component_configs: [
          { id: "X", chunks: 100 },
          { id: "Y", chunks: 100 },
          { id: "Z", chunks: 100 }
        ],
        buffer_size: 1
      )

      # Template + 300 component chunks
      expect(chunks.size).to eq(301)
      expect(chunks.first).to eq("TEMPLATE\n")
    end

    it "server handles multiple sequential disconnects then recovers" do
      # First disconnect: early
      run_disconnect_test(
        component_configs: components,
        disconnect_after: 5,
        buffer_size: 1
      )

      # Second disconnect: mid-stream
      run_disconnect_test(
        component_configs: [{ id: "D", chunks: 500 }, { id: "E", chunks: 500 }],
        disconnect_after: 200,
        buffer_size: 1
      )

      # Third: full successful stream
      chunks = run_healthy_stream(
        component_configs: [{ id: "F", chunks: 50 }],
        buffer_size: 1
      )

      expect(chunks.size).to eq(51)
    end
  end
end
