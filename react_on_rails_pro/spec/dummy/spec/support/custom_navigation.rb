# frozen_string_literal: true

FETCH_LOG_MESSAGE = "REACT_ON_RAILS_PRO_DUMMY_APP: FETCH"

module CustomNavigation
  def navigate_with_streaming(path, base_url = nil)
    base_url ||= Capybara.app_host || Capybara.current_session.server.base_url
    empty_page_url = URI.join(base_url, "/empty").to_s
    # The app must create an empty page, so we need to navigate to it first
    # We need to navigate to an empty page first to avoid CORS issues and to update the page host
    visit empty_page_url

    override_fetch_for_logging
    url = URI.join(base_url, path).to_s
    inject_javascript_to_stream_page(url)
    until finished_streaming?
      chunk = next_streamed_page_chunk
      break if chunk.nil?

      yield chunk if block_given?
    end
  end

  # Returns the next chunk of the streamed page content
  # Blocks until a chunk is available or the page has finished loading
  # Raises an error if no page is currently being streamed and there are no chunks to process
  def next_streamed_page_chunk
    # Check if we're either actively streaming or have chunks to process
    raise "No page is currently being streamed. Call navigate_with_streaming first." if finished_streaming?

    loop do
      loaded_content = page.evaluate_script(<<~JS)
        (function() {
          const content = window.loaded_content;
          window.loaded_content = undefined;
          return content;
        })();
      JS
      if loaded_content
        page.execute_script("window.processNextChunk()")
        return loaded_content
      end

      # If streaming is finished and no more chunks, we're done
      return nil if finished_streaming?

      sleep 0.1
    end
  end

  # Logs all fetch requests happening while streaming the page using the `navigate_with_streaming` method
  def fetch_requests_while_streaming
    logs = page.driver.browser.logs.get(:browser)
    fetch_requests = logs.select { |log| log.message.include?(FETCH_LOG_MESSAGE) }
    fetch_requests.map do |log|
      double_stringified_fetch_info = log.message.split(FETCH_LOG_MESSAGE.to_json).last
      JSON.parse(JSON.parse(double_stringified_fetch_info), symbolize_names: true)
    end
  end

  private

  def finished_streaming?
    page.evaluate_script(<<~JS)
      window.streaming_state === 'finished' &&
      window.chunkBuffer.length === 0 &&
      !window.loaded_content
    JS
  end

  def override_fetch_for_logging
    page.execute_script(<<~JS)
      if (typeof window.originalFetch !== 'function') {
        window.originalFetch = window.fetch;
        window.fetch = function(url, options) {
          const stringifiedFetchInfo = JSON.stringify({ url, options });
          console.debug('#{FETCH_LOG_MESSAGE}', stringifiedFetchInfo);
          return window.originalFetch(url, options);
        }
      }
    JS
  end

  def inject_javascript_to_stream_page(url)
    js = <<-JS
      (function() {
        history.replaceState({}, '', '#{url}');
        document.open();

        // Create a buffer for chunks and initialize streaming state
        window.chunkBuffer = [];
        window.streaming_state = 'streaming';

        // Define the global function to process the next chunk
        window.processNextChunk = function() {
          if (window.chunkBuffer.length === 0 || window.loaded_content) {
            return;
          }

          const chunk = window.chunkBuffer.shift();
          document.write(chunk);
          window.loaded_content = chunk;

          if (window.chunkBuffer.length === 0 && window.streaming_state === 'finished') {
            document.close();
          }
        };

        // Fetch the actual HTML content
        originalFetch('#{url}')
          .then(response => {
            const reader = response.body.getReader();
            const decoder = new TextDecoder();
            #{streaming_reader_js}
          });
      })();
    JS
    page.execute_script(js)
  end

  def streaming_reader_js
    <<~JS
      function readChunk() {
        reader.read().then(({ done, value }) => {
          if (done) {
            window.streaming_state = 'finished';
            if (window.chunkBuffer.length === 0) {
              document.close();
            }
            return;
          }

          const chunk = decoder.decode(value);
          window.chunkBuffer.push(chunk);

          // If this is the first chunk, set it as loaded_content
          if (window.chunkBuffer.length === 1 && !window.loaded_content) {
            window.processNextChunk();
          }

          readChunk();
        });
      }

      readChunk();
    JS
  end
end
