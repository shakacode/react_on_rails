# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"
require "react_on_rails_pro/renderer_http_client"

RSpec.describe ReactOnRailsPro::StreamRequest do
  let(:retry_limit) { 2 }

  before do
    config = instance_double(ReactOnRailsPro::Configuration, renderer_request_retry_limit: retry_limit)
    allow(ReactOnRailsPro).to receive(:configuration).and_return(config)
  end

  def to_length_prefixed(html, metadata_overrides = {})
    metadata = {
      "consoleReplayScript" => "", "hasErrors" => false,
      "isShellReady" => true, "payloadType" => "string"
    }.merge(metadata_overrides)
    content_bytes = html.bytesize.to_s(16).rjust(8, "0")
    "#{metadata.to_json}\t#{content_bytes}\n#{html}"
  end

  def mock_ok_response(*chunks)
    ReactOnRailsPro::RendererHttpClient::Response.new do |yielder, status_assigner|
      status_assigner.call(200)
      chunks.each { |c| yielder.call(c) }
    end
  end

  def mock_error_response(status, *chunks)
    ReactOnRailsPro::RendererHttpClient::Response.new do |yielder, status_assigner|
      status_assigner.call(status)
      chunks.each { |c| yielder.call(c) }
    end
  end

  describe ".create" do
    it "returns a StreamDecorator instance" do
      result = described_class.create { nil }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end

  describe "#process_response_chunks" do
    subject(:request) { described_class.send(:new) { nil } }

    it "parses length-prefixed chunks and yields result hashes" do
      response = mock_ok_response(to_length_prefixed("<div>Hello</div>"))

      yielded = []
      request.send(:process_response_chunks, response) { |chunk| yielded << chunk }

      expect(yielded.size).to eq(1)
      expect(yielded.first["html"]).to eq("<div>Hello</div>")
      expect(yielded.first["hasErrors"]).to be false
      expect(yielded.first["consoleReplayScript"]).to eq("")
      expect(request.http_status).to eq(200)
      expect(request.http_status_recorded?).to be(true)
    end

    it "skips LPP parsing when response has error status" do
      response = mock_error_response(500, "error details")

      yielded = []
      expect do
        request.send(:process_response_chunks, response) { |chunk| yielded << chunk }
      end.to raise_error(ReactOnRailsPro::RendererHttpClient::HTTPError)

      expect(yielded).to be_empty
      expect(request.http_status).to eq(500)
      expect(request.http_status_recorded?).to be(true)
    end

    it "records status for empty responses" do
      response = ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, status_assigner|
        status_assigner.call(204)
      end

      request.send(:process_response_chunks, response) { |_| nil }

      expect(request.http_status).to eq(204)
      expect(request.http_status_recorded?).to be(true)
    end

    context "with length-prefixed protocol parsing" do
      it "parses multiple LPP chunks from a single response" do
        data = to_length_prefixed("<div>First</div>") + to_length_prefixed("<div>Second</div>")
        response = mock_ok_response(data)

        yielded = []
        request.send(:process_response_chunks, response) { |chunk| yielded << chunk }

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
        request.send(:process_response_chunks, response) { |chunk| yielded << chunk }

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
        request.send(:process_response_chunks, response) { |chunk| yielded << chunk }

        expect(yielded.size).to eq(1)
        expect(yielded.first["html"]).to be_a(Hash)
        expect(yielded.first["html"]["serverHtml"]).to eq("<div/>")
      end

      it "raises on malformed header with missing tab separator" do
        malformed = "{\"payloadType\":\"string\"}00000005\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /missing tab separator/)
      end

      it "raises on invalid hex content length" do
        malformed = "{\"payloadType\":\"string\"}\tZZZZZZZZ\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /Invalid content length hex/)
      end

      it "raises on invalid metadata JSON" do
        malformed = "not-json\t00000005\nhello"
        response = mock_ok_response(malformed)

        expect do
          request.send(:process_response_chunks, response) { |_| nil }
        end.to raise_error(ReactOnRails::Error, /invalid metadata JSON/)
      end

      it "recovers across separate process_response_chunks calls" do
        malformed = "no-tab-here\n"
        valid = to_length_prefixed("<div>Valid</div>")

        response1 = mock_ok_response(malformed)
        expect do
          request.send(:process_response_chunks, response1) { |_| nil }
        end.to raise_error(ReactOnRails::Error)

        response2 = mock_ok_response(valid)
        yielded = []
        request.send(:process_response_chunks, response2) { |chunk| yielded << chunk }
        expect(yielded.size).to eq(1)
        expect(yielded.first["html"]).to eq("<div>Valid</div>")
      end
    end

    it "ignores responses without status metadata" do
      request.send(:record_status, Object.new)

      expect(request.http_status).to be_nil
      expect(request.http_status_recorded?).to be(false)
    end

    it "records response status only once" do
      status_calls = 0
      response = Object.new
      response.define_singleton_method(:status) do
        status_calls += 1
        200
      end

      request.send(:record_status, response)
      request.send(:record_status, response)

      expect(status_calls).to eq(1)
      expect(request.http_status).to eq(200)
    end
  end

  describe "#each_chunk with tasks" do
    it "passes tasks array to request_executor block" do
      tasks_received = nil
      response = mock_ok_response(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, tasks|
        tasks_received = tasks
        response
      end

      stream.each_chunk(&:itself)

      expect(tasks_received).to be_an(Array)
    end

    it "waits for tasks after yielding chunks" do
      task_waited = false
      response = mock_ok_response(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, tasks|
        tasks.push(Async::Task.current.async { task_waited = true })
        response
      end

      stream.each_chunk(&:itself)

      expect(task_waited).to be true
    end
  end

  describe "error handling" do
    it "retries TimeoutError before first chunk, then raises after exhausting retries" do
      call_count = 0
      stream = described_class.create do |_send_bundle, _tasks|
        call_count += 1
        ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, _status_assigner|
          raise ReactOnRailsPro::RendererHttpClient::TimeoutError, "read timeout"
        end
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Time out error while server side render streaming a component/
      )
      expect(call_count).to eq(retry_limit + 1)
    end

    it "retries ConnectionError before first chunk, then raises after exhausting retries" do
      call_count = 0
      stream = described_class.create do |_send_bundle, _tasks|
        call_count += 1
        ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, _status_assigner|
          raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "Connection refused"
        end
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Connection error while server side render streaming a component/
      )
      expect(call_count).to eq(retry_limit + 1)
    end

    it "raises immediately on TimeoutError after first chunk is received" do
      call_count = 0
      stream = described_class.create do |_send_bundle, _tasks|
        call_count += 1
        ReactOnRailsPro::RendererHttpClient::Response.new do |yielder, status_assigner|
          status_assigner.call(200)
          yielder.call(to_length_prefixed("chunk1"))
          raise ReactOnRailsPro::RendererHttpClient::TimeoutError, "read timeout"
        end
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Time out error while server side render streaming a component/
      )
      expect(call_count).to eq(1)
    end

    it "raises immediately on ConnectionError after first chunk is received" do
      call_count = 0
      stream = described_class.create do |_send_bundle, _tasks|
        call_count += 1
        ReactOnRailsPro::RendererHttpClient::Response.new do |yielder, status_assigner|
          status_assigner.call(200)
          yielder.call(to_length_prefixed("chunk1"))
          raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "Connection reset"
        end
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Connection error while server side render streaming a component/
      )
      expect(call_count).to eq(1)
    end

    it "retries transport error then succeeds" do
      call_count = 0
      stream = described_class.create do |_send_bundle, _tasks|
        call_count += 1
        if call_count == 1
          ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, _status_assigner|
            raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "Connection refused"
          end
        else
          mock_ok_response(to_length_prefixed("ok"))
        end
      end

      chunks = []
      stream.each_chunk { |c| chunks << c }
      expect(call_count).to eq(2)
      expect(chunks.first).to include("html" => "ok")
      expect(stream.http_status).to eq(200)
      expect(stream.http_status_recorded?).to be(true)
    end

    it "stops and clears tasks before retrying on transport error" do
      call_count = 0
      task_stopped = false

      stream = described_class.create do |_send_bundle, tasks|
        call_count += 1
        if call_count == 1
          tasks.push(Async::Task.current.async { task_stopped = true })
          ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, _status_assigner|
            raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "Connection refused"
          end
        else
          expect(tasks).to be_empty
          mock_ok_response(to_length_prefixed("ok"))
        end
      end

      stream.each_chunk(&:itself)
      expect(call_count).to eq(2)
      expect(task_stopped).to be true
    end

    it "raises ReactOnRailsPro::Error on HTTP 400 (bad request)" do
      stream = described_class.create do |_send_bundle, _tasks|
        mock_error_response(400, "bad request body")
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Renderer rejected malformed request or hit an unhandled VM error/
      )
    end

    it "raises ReactOnRailsPro::Error on STATUS_INCOMPATIBLE (412)" do
      stream = described_class.create do |_send_bundle, _tasks|
        mock_error_response(412, "incompatible")
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end

    it "raises ReactOnRailsPro::Error on unexpected status codes" do
      stream = described_class.create do |_send_bundle, _tasks|
        mock_error_response(503, "service unavailable")
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Unexpected response code from renderer: 503/
      )
      expect(stream.http_status).to eq(503)
      expect(stream.http_status_recorded?).to be(true)
    end

    it "retries with bundle upload on HTTP 410 (send bundle)" do
      call_count = 0

      stream = described_class.create do |send_bundle, _tasks|
        call_count += 1
        if call_count == 1
          mock_error_response(410, "bundle not found")
        else
          expect(send_bundle).to be true
          mock_ok_response(to_length_prefixed("ok"))
        end
      end

      chunks = []
      stream.each_chunk { |c| chunks << c }
      expect(call_count).to eq(2)
      expect(chunks.first).to include("html" => "ok")
    end

    it "prevents infinite loop on duplicate 410 responses" do
      stream = described_class.create do |_send_bundle, _tasks|
        mock_error_response(410, "bundle not found")
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end

    it "stops and clears tasks before retrying on 410" do
      call_count = 0
      task_stopped = false

      stream = described_class.create do |_send_bundle, tasks|
        call_count += 1
        if call_count == 1
          tasks.push(Async::Task.current.async { task_stopped = true })
          mock_error_response(410, "bundle not found")
        else
          expect(tasks).to be_empty
          mock_ok_response(to_length_prefixed("ok"))
        end
      end

      stream.each_chunk(&:itself)

      expect(call_count).to eq(2)
      expect(task_stopped).to be true
    end

    it "clears retry status before transport failures" do
      allow(ReactOnRailsPro).to receive(:configuration).and_return(
        instance_double(ReactOnRailsPro::Configuration, renderer_request_retry_limit: 0)
      )
      call_count = 0

      stream = described_class.create do |send_bundle, _tasks|
        call_count += 1
        if call_count == 1
          mock_error_response(410, "bundle not found")
        else
          expect(send_bundle).to be true
          ReactOnRailsPro::RendererHttpClient::Response.new do |_yielder, _status_assigner|
            raise ReactOnRailsPro::RendererHttpClient::ConnectionError, "connection reset"
          end
        end
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Connection error while server side render streaming a component/
      )
      expect(call_count).to eq(2)
      expect(stream.http_status).to be_nil
      expect(stream.http_status_recorded?).to be(false)
    end
  end

  describe "first_chunk_warn_callback" do
    it "invokes callback with time to first chunk" do
      callback_time = nil
      callback = ->(time) { callback_time = time }
      response = mock_ok_response(to_length_prefixed("chunk"))

      stream = described_class.create(first_chunk_warn_callback: callback) do |_send_bundle, _tasks|
        response
      end

      stream.each_chunk(&:itself)
      expect(callback_time).to be_a(Float)
      expect(callback_time).to be >= 0
    end

    it "invokes callback only once for multiple chunks" do
      callback_count = 0
      callback = ->(_time) { callback_count += 1 }
      data = to_length_prefixed("chunk1") + to_length_prefixed("chunk2")
      response = mock_ok_response(data)

      stream = described_class.create(first_chunk_warn_callback: callback) do |_send_bundle, _tasks|
        response
      end

      stream.each_chunk(&:itself)
      expect(callback_count).to eq(1)
    end
  end
end
