# frozen_string_literal: true

require "async"
require "async/queue"
require_relative "spec_helper"

# Test controller that includes ReactOnRailsPro::Stream for testing streaming behavior
class StreamController
  include ReactOnRailsPro::Stream

  attr_reader :response

  def initialize(component_queues:, initial_response: "TEMPLATE")
    @component_queues = component_queues
    @initial_response = initial_response
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

RSpec.describe ReactOnRailsPro::Stream do
  describe "Component streaming concurrency" do
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
      allow(mocked_stream).to receive(:closed?).and_return(false)
      allow(controller).to receive(:response).and_return(mocked_response)

      [component_queues, controller, mocked_stream]
    end

    it "streams components concurrently" do
      queues, controller, stream = setup_stream_test

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
      queues, controller, stream = setup_stream_test

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

    it "handles empty component list" do
      _queues, controller, stream = setup_stream_test(component_count: 0)

      run_stream(controller) do |_parent|
        sleep 0.1
      end

      expect(stream).to have_received(:write).with("TEMPLATE")
      expect(stream).to have_received(:close)
    end

    it "handles single component" do
      queues, controller, stream = setup_stream_test(component_count: 1)

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
      queues, controller, stream = setup_stream_test(component_count: 1)

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
        queues, controller, stream = setup_stream_test(component_count: 1)

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
        queues, controller, stream = setup_stream_test(component_count: 1)

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
    end
  end
end
