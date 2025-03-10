# frozen_string_literal: true

require_relative "spec_helper"

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
    # That's why it shouldn't be used in streamed requests
    it "blocks until the stream is complete" do
      mocked_block = mock_block

      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk\n")
        expect(mocked_block).not_to have_received(:call)

        yielder.call("Second chunk\n")
        expect(mocked_block).not_to have_received(:call)

        yielder.call("Final chunk\n")
        expect(mocked_block).not_to have_received(:call)
      end

      response = http.get(path, stream: true)
      response.raise_for_status
      response.each_line(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunk")
      expect(mocked_block).to have_received(:call).with("Second chunk")
      expect(mocked_block).to have_received(:call).with("Final chunk")
    end

    it "can catch errors by calling raise_for_status" do
      mock_streaming_response(url, 410) do |yielder|
        yielder.call("Bundle Required")
      end

      response = http.get(path, stream: true)

      expect do
        response.raise_for_status
      end.to(raise_error do |error|
        expect(error.response.status).to eq(410)
        expect(error.response.body).to eq("Bundle Required")
      end)

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
    it "is blocking until the stream is complete" do
      mocked_block = mock_block

      mock_streaming_response(url, 200) do |yielder|
        yielder.call("First chunk")
        expect(mocked_block).not_to have_received(:call)

        yielder.call("Second chunk")
        expect(mocked_block).not_to have_received(:call)

        yielder.call("Final chunk")
        expect(mocked_block).not_to have_received(:call)
      end

      response = http.get(path, stream: true)
      expect(response.status).to eq(200)
      response.each(&mocked_block.block)
      expect(mocked_block).to have_received(:call).with("First chunkSecond chunkFinal chunk")
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
  end
end
