# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"
require "async/barrier"
require "httpx"

HTTPX::Plugins.load_plugin(:stream)

RSpec.describe ReactOnRailsPro::StreamRequest do
  # Wraps a string in the length-prefixed wire format for mock streaming responses.
  def to_length_prefixed(html, metadata_overrides = {})
    metadata = {
      "consoleReplayScript" => "", "hasErrors" => false,
      "isShellReady" => true, "payloadType" => "string"
    }.merge(metadata_overrides)
    content_bytes = html.bytesize.to_s(16).rjust(8, "0")
    "#{metadata.to_json}\t#{content_bytes}\n#{html}"
  end

  # Builds a mock response that yields the given raw chunks and reports the given status.
  def mock_ok_response(*raw_chunks)
    response = Object.new
    response.define_singleton_method(:each) { |&blk| raw_chunks.each { |c| blk.call(c) } }
    response.define_singleton_method(:status) { 200 }
    allow(response).to receive(:is_a?).and_call_original
    allow(response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
    response
  end

  def httpx_stream_response_with_status_error(error, *raw_chunks)
    response = HTTPX::StreamResponse.allocate
    response.define_singleton_method(:each) { |&blk| raw_chunks.each { |c| blk.call(c) } }
    response.define_singleton_method(:status) { raise error }
    response
  end

  describe ".create" do
    it "returns a StreamDecorator instance" do
      # Passed block is not called until #each_chunk is invoked, so we can just pass a no-op block here.
      # As it won't be called during this test
      result = described_class.create { nil }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end

  describe "#process_response_chunks" do
    subject(:request) { described_class.send(:new) { nil } }

    let(:error_body) { +"" }

    it "treats responses without status delegation as error responses" do
      response = Class.new do
        def each
          yield "Failed request body"
        end

        def status
          raise NoMethodError, "undefined method `status`"
        end
      end.new
      expect(Rails.logger).to receive(:warn).with(/ignoring error while reading stream response status: NoMethodError/)

      yielded_chunks = []
      expect do
        request.send(:process_response_chunks, response, error_body) do |chunk|
          yielded_chunks << chunk
        end
      end.to raise_error(
        ReactOnRailsPro::Error,
        /unreadable stream response status after buffering 19 bytes/
      )

      expect(error_body).to eq("Failed request body")
      expect(yielded_chunks).to be_empty
      expect(request.status).to be_nil
      expect(request.http_status_recorded?).to be(true)
    end

    it "parses length-prefixed chunks and yields result hashes" do
      response = mock_ok_response(to_length_prefixed("<div>Hello</div>"))

      yielded = []
      request.send(:process_response_chunks, response, error_body) { |chunk| yielded << chunk }

      expect(yielded.size).to eq(1)
      expect(yielded.first["html"]).to eq("<div>Hello</div>")
      expect(yielded.first["hasErrors"]).to be false
      expect(yielded.first["consoleReplayScript"]).to eq("")
    end

    it "collects body into error_body when response has error status" do
      response = Class.new do
        define_method(:each) { |&blk| blk.call("error details") }
        define_method(:status) { 500 }
        define_method(:is_a?) { |klass| klass == HTTPX::ErrorResponse ? false : super(klass) }
      end.new

      yielded = []
      request.send(:process_response_chunks, response, error_body) { |chunk| yielded << chunk }

      expect(yielded).to be_empty
      expect(error_body).to eq("error details")
    end

    it "treats unrecorded status as an error status" do
      expect(request.send(:response_has_error_status?)).to be(true)
    end

    it "clears previous status before parsing a response attempt" do
      request.instance_variable_set(:@status, ReactOnRailsPro::STATUS_SEND_BUNDLE)
      response = Class.new do
        def each
          yield "body"
        end

        def status
          500
        end

        def is_a?(klass)
          klass == HTTPX::ErrorResponse ? false : super
        end
      end.new

      request.send(:process_response_chunks, response, error_body) { |_| nil }

      expect(request.status).to eq(500)
    end

    it "clears previous error body before parsing a response attempt" do
      error_body << "previous attempt"
      response = Class.new do
        def each
          yield "current attempt"
        end

        def status
          500
        end

        def is_a?(klass)
          klass == HTTPX::ErrorResponse ? false : super
        end
      end.new

      request.send(:process_response_chunks, response, error_body) { |_| nil }

      expect(error_body).to eq("current attempt")
    end

    it "marks status as attempted when status extraction raises" do
      response = Class.new do
        def each
          yield "body"
        end

        def status
          raise "status unavailable"
        end
      end.new

      expect do
        request.send(:process_response_chunks, response, error_body) { |_| nil }
      end.to raise_error(RuntimeError, /status unavailable/)
      expect(request.send(:response_has_error_status?)).to be(true)
    end

    it "treats HTTPX stream status argument errors as unknown response status" do
      error = ArgumentError.new("wrong number of arguments (given 1, expected 0)")
      response = httpx_stream_response_with_status_error(error, "body")
      expect(Rails.logger).to receive(:warn).with(/ignoring error while reading stream response status: ArgumentError/)

      expect do
        request.send(:process_response_chunks, response, error_body) { |_| nil }
      end.to raise_error(
        ReactOnRailsPro::Error,
        /unreadable stream response status after buffering 4 bytes/
      )
      expect(error_body).to eq("body")
      expect(request.status).to be_nil
      expect(request.http_status_recorded?).to be(true)
    end

    it "raises HTTPX stream status argument errors after the workaround version" do
      error = ArgumentError.new("wrong number of arguments (given 1, expected 0)")
      response = httpx_stream_response_with_status_error(error, "body")
      allow(Gem).to receive(:loaded_specs).and_return(
        "httpx" => Struct.new(:version).new(Gem::Version.new("1.7.1"))
      )

      expect do
        request.send(:process_response_chunks, response, error_body) { |_| nil }
      end.to raise_error(ArgumentError, /wrong number of arguments/)
    end

    it "warns when applying the HTTPX stream status workaround without a loaded gem version" do
      error = ArgumentError.new("wrong number of arguments (given 1, expected 0)")
      response = httpx_stream_response_with_status_error(error, "body")
      allow(Gem).to receive(:loaded_specs).and_return({})
      expect(Rails.logger).to receive(:warn)
        .with(/loaded httpx version is unavailable: ArgumentError/)

      expect do
        request.send(:process_response_chunks, response, error_body) { |_| nil }
      end.to raise_error(
        ReactOnRailsPro::Error,
        /unreadable stream response status after buffering 4 bytes/
      )

      expect(error_body).to eq("body")
    end

    it "raises non-HTTPX ArgumentError status read failures" do
      response = Class.new do
        def each
          yield "body"
        end

        def status
          raise ArgumentError, "status unavailable"
        end
      end.new

      expect do
        request.send(:process_response_chunks, response, error_body) { |_| nil }
      end.to raise_error(ArgumentError, /status unavailable/)
      expect(request.send(:response_has_error_status?)).to be(true)
    end

    context "with length-prefixed protocol parsing" do
      it "parses multiple LPP chunks from a single response" do
        data = to_length_prefixed("<div>First</div>") + to_length_prefixed("<div>Second</div>")
        response = mock_ok_response(data)

        yielded = []
        request.send(:process_response_chunks, response, error_body) { |chunk| yielded << chunk }

        expect(yielded.size).to eq(2)
        expect(yielded[0]["html"]).to eq("<div>First</div>")
        expect(yielded[1]["html"]).to eq("<div>Second</div>")
      end

      it "handles data split across multiple HTTP chunks" do
        full = to_length_prefixed("<div>Split</div>")
        mid = full.bytesize / 2
        chunk1 = full.byteslice(0, mid)
        chunk2 = full.byteslice(mid, full.bytesize - mid)
        response = mock_ok_response(chunk1, chunk2)

        yielded = []
        request.send(:process_response_chunks, response, error_body) { |chunk| yielded << chunk }

        expect(yielded.size).to eq(1)
        expect(yielded.first["html"]).to eq("<div>Split</div>")
      end

      it "dispatches payloadType 'object' as parsed JSON" do
        json_content = '{"serverHtml":"<div/>","clientProps":{}}'
        metadata = {
          "consoleReplayScript" => "", "hasErrors" => false,
          "isShellReady" => true, "payloadType" => "object"
        }
        content_bytes = json_content.bytesize.to_s(16).rjust(8, "0")
        lpp_data = "#{metadata.to_json}\t#{content_bytes}\n#{json_content}"
        response = mock_ok_response(lpp_data)

        yielded = []
        request.send(:process_response_chunks, response, error_body) { |chunk| yielded << chunk }

        expect(yielded.size).to eq(1)
        expect(yielded.first["html"]).to be_a(Hash)
        expect(yielded.first["html"]["serverHtml"]).to eq("<div/>")
      end

      it "raises on malformed header with missing tab separator" do
        malformed = "{\"payloadType\":\"string\"}00000005\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response, error_body) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /missing tab separator/)
      end

      it "raises on invalid hex content length" do
        malformed = "{\"payloadType\":\"string\"}\tZZZZZZZZ\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response, error_body) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /Invalid content length hex/)
      end

      it "raises on invalid metadata JSON" do
        malformed = "not-json\t00000005\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response, error_body) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /invalid metadata JSON/)
      end

      it "becomes no-op after a protocol error" do
        # First chunk is malformed, second is valid
        malformed = "no-tab-here\n"
        valid = to_length_prefixed("<div>Valid</div>")
        response = mock_ok_response(malformed)

        # Parser enters error state on first chunk
        expect do
          request.send(:process_response_chunks, response, error_body) { |_| nil }
        end.to raise_error(ReactOnRails::Error)

        # New response through a fresh process_response_chunks call would work,
        # but the SAME parser instance (if reused) would be in error state.
        # Since process_response_chunks creates a new parser each time,
        # we verify a second call still works independently.
        response2 = mock_ok_response(valid)
        yielded = []
        request.send(:process_response_chunks, response2, error_body) { |chunk| yielded << chunk }
        expect(yielded.size).to eq(1)
        expect(yielded.first["html"]).to eq("<div>Valid</div>")
      end
    end
  end

  # Unverified doubles are required for streaming responses because:
  # 1. HTTP streaming responses don't have a dedicated class type in HTTPX
  # 2. The #each method for streaming is added dynamically at runtime
  # 3. The interface varies based on the streaming mode (HTTP/2, chunked, etc.)
  # rubocop:disable RSpec/VerifiedDoubles
  describe "#each_chunk with barrier" do
    it "passes barrier to request_executor block" do
      barrier_received = nil
      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, barrier|
        barrier_received = barrier
        mock_response
      end

      stream.each_chunk(&:itself)

      expect(barrier_received).to be_a(Async::Barrier)
    end

    it "calls barrier.wait after yielding chunks" do
      barrier = Async::Barrier.new
      allow(Async::Barrier).to receive(:new).and_return(barrier)
      expect(barrier).to receive(:wait)

      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      stream.each_chunk(&:itself)
    end

    it "exposes the response status after streaming" do
      mock_response = double(HTTPX::StreamResponse, status: 204)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      expect(stream.http_status_recorded?).to be(false)
      stream.each_chunk(&:itself)

      expect(stream.status).to eq(204)
      expect(stream.http_status).to eq(204)
      expect(stream.http_status_recorded?).to be(true)
    end

    it "exposes the response status for empty streaming responses" do
      drained = false
      mock_response = double(HTTPX::StreamResponse)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each) { drained = true }
      allow(mock_response).to receive(:status) do
        expect(drained).to be(true)
        204
      end

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      stream.each_chunk(&:itself)

      expect(stream.status).to eq(204)
    end

    it "reads the response status once per streaming response" do
      mock_response = double(HTTPX::StreamResponse)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      expect(mock_response).to receive(:status).once.and_return(200)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("one")).and_yield(to_length_prefixed("two"))

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      chunks = []
      stream.each_chunk { |chunk| chunks << chunk }

      expect(chunks.size).to eq(2)
    end

    it "raises after buffering HTTPX error response bodies without reading status" do
      mock_response = double(HTTPX::ErrorResponse)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(true)
      expect(mock_response).not_to receive(:status)
      allow(mock_response).to receive(:each).and_yield("renderer error")

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /unreadable stream response status after buffering 14 bytes/
      )

      expect(stream.status).to be_nil
      expect(stream.http_status_recorded?).to be(true)
    end

    it "allows empty HTTPX error responses with unavailable status" do
      mock_response = double(HTTPX::ErrorResponse)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(true)
      expect(mock_response).not_to receive(:status)
      allow(mock_response).to receive(:each)

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      chunks = []
      expect { stream.each_chunk { |chunk| chunks << chunk } }.not_to raise_error

      expect(chunks).to be_empty
      expect(stream.status).to be_nil
      expect(stream.http_status_recorded?).to be(true)
    end

    it "raises when stream response status cannot be read" do
      mock_response = double(HTTPX::StreamResponse)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:status).and_raise(NoMethodError)
      allow(mock_response).to receive(:each).and_yield("renderer error")
      expect(Rails.logger).to receive(:warn).with(/ignoring error while reading stream response status: NoMethodError/)

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      chunks = []
      expect { stream.each_chunk { |chunk| chunks << chunk } }.to raise_error(
        ReactOnRailsPro::Error,
        /unreadable stream response status after buffering 14 bytes/
      )

      expect(chunks).to be_empty
      expect(stream.status).to be_nil
      expect(stream.http_status_recorded?).to be(true)
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  # rubocop:disable RSpec/VerifiedDoubles
  describe "error handling" do
    def build_http_error(status)
      response = double("response", status: status, headers: {}, body: "")
      HTTPX::HTTPError.new(response)
    end

    it "raises ReactOnRailsPro::Error on HTTPX::ReadTimeoutError" do
      mock_request = double("request")
      mock_response = double("response")
      timeout_error = HTTPX::ReadTimeoutError.new(mock_request, mock_response, 5)

      stream = described_class.create do |_send_bundle, _barrier|
        raise timeout_error
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Time out error while server side render streaming a component/
      )
    end

    it "raises ReactOnRailsPro::Error on HTTP 400 (bad request)" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(400)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Renderer rejected malformed request or hit an unhandled VM error/
      )
    end

    it "uses the recorded status in HTTP 400 error messages" do
      status_calls = 0
      response = double("response", headers: {}, body: "")
      allow(response).to receive(:status) do
        status_calls += 1
        raise NoMethodError, "status unavailable" if status_calls > 2

        400
      end
      http_error = HTTPX::HTTPError.new(response)
      stream = described_class.create do |_send_bundle, _barrier|
        raise http_error
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Renderer rejected malformed request or hit an unhandled VM error: 400:/
      )
    end

    it "preserves HTTP error handling when status extraction unexpectedly fails" do
      status_calls = 0
      status_error = RuntimeError.new("status unavailable")
      response = double("response", headers: {}, body: "")
      allow(response).to receive(:status) do
        status_calls += 1
        raise status_error if status_calls > 1

        503
      end
      http_error = HTTPX::HTTPError.new(response)
      stream = described_class.create do |_send_bundle, _barrier|
        raise http_error
      end
      expect(Rails.logger).to receive(:warn).with(
        /ignoring unexpected error while reading HTTP error response status: RuntimeError/
      )

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error) do |error|
        expect(error.message).to eq(
          "Renderer returned an unreadable HTTP error response (RuntimeError: status unavailable)"
        )
        expect(error.cause).to eq(status_error)
      end
      expect(stream.status).to be_nil
    end

    it "raises ReactOnRailsPro::Error on STATUS_INCOMPATIBLE (412)" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(412)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end

    it "raises ReactOnRailsPro::Error on unexpected status codes" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(503)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Unexpected response code from renderer: 503/
      )
    end

    it "retries with bundle upload on HTTP 410 (send bundle)" do
      call_count = 0
      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("ok"))

      stream = described_class.create do |send_bundle, _barrier|
        call_count += 1
        raise build_http_error(410) if call_count == 1

        expect(send_bundle).to be true
        mock_response
      end

      chunks = []
      stream.each_chunk { |c| chunks << c }
      expect(call_count).to eq(2)
      expect(chunks.first).to include("html" => "ok")
      expect(stream.status).to eq(200)
    end

    it "prevents infinite loop on duplicate 410 responses" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(410)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end

    it "records status when HTTPX raises before yielding chunks" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(503)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Unexpected response code from renderer: 503/
      )
      expect(stream.status).to eq(503)
    end

    it "bubbles up HTTPX::ConnectionError when node renderer is unreachable" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise HTTPX::ConnectionError, "Connection refused - connect(2) for 127.0.0.1:3500"
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(HTTPX::ConnectionError, /Connection refused/)
    end

    it "propagates connection errors without calling barrier.wait" do
      barrier_wait_called = false
      stream = described_class.create do |_send_bundle, barrier|
        allow(barrier).to receive(:wait) { barrier_wait_called = true }
        raise HTTPX::ConnectionError, "connection reset"
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(HTTPX::ConnectionError)
      expect(barrier_wait_called).to be false
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end
