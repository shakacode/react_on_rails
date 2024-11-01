# frozen_string_literal: true

module CustomNavigation
  def navigate_with_streaming(path, base_url = nil)
    base_url ||= Capybara.app_host || Capybara.current_session.server.base_url
    empty_page_url = URI.join(base_url, "/empty").to_s
    # The app must create an empty page, so we need to navigate to it first
    # We need to navigate to an empty page first to avoid CORS issues and to update the page host
    visit empty_page_url
    url = URI.join(base_url, path).to_s

    inject_javascript_to_stream_page(url)

    loop do
      # check if the page has content
      if page.evaluate_script("window.loaded_content")
        loaded_content = page.evaluate_script("window.loaded_content;")
        page.evaluate_script("window.loaded_content = undefined;")
        yield loaded_content
      end

      # check if the page has finished loading
      if page.evaluate_script("window.finished_loading")
        page.evaluate_script("window.finished_loading = false;")
        break
      end

      # Sleep briefly to avoid busy-waiting.
      sleep 0.1
    end
  end

  private

  def inject_javascript_to_stream_page(url)
    js = <<-JS
      (function() {
        history.replaceState({}, '', '#{url}');
        document.open();
        // Fetch the actual HTML content
        fetch('#{url}')
          .then(response => {
            const reader = response.body.getReader();
            const decoder = new TextDecoder();

            function readChunk() {
              return reader.read().then(({ done, value }) => {
                if (done) {
                  document.close();
                  window.finished_loading = true;
                  return;
                }
                const chunk = decoder.decode(value);
                document.write(chunk);
                window.loaded_content = chunk;
                readChunk();
              });
            }
            readChunk();
          });
      })();
    JS
    page.execute_script(js)
  end
end
