# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

RequestDetails = Struct.new(:original_url, :env)

# This module is created to provide stub methods for `render_to_string` and `response`
# These methods will be mocked in the tests to prevent "<object> does not implement <method>" errors
# when these methods are called during testing.
module StreamingTestHelpers
  def render_to_string(*args); end
  def response; end
end

describe ReactOnRailsProHelper, type: :helper do
  # In order to test the pro helper, we need to load the methods from the regular helper.
  # I couldn't see any easier way to do this.
  include ReactOnRails::Helper
  include ReactOnRailsPro::Stream
  include Shakapacker::Helper
  include ApplicationHelper

  before do
    allow(self).to receive(:request) {
      RequestDetails.new("http://foobar.com/development", { "HTTP_ACCEPT_LANGUAGE" => "en" })
    }
  end

  let(:hash) do
    {
      hello: "world",
      free: "of charge",
      x: "</script><script>alert('foo')</script>"
    }
  end

  let(:json_string_sanitized) do
    '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip' \
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
  end

  let(:json_string_unsanitized) do
    "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
  end

  describe "#cached_react_component", :caching, :requires_webpack_assets do
    before { allow(SecureRandom).to receive(:uuid).and_return(0, 1, 2, 3) }

    let(:base_component_cache_key) do
      "ror_component/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}"
    end
    let(:base_cache_key_with_prerender) do
      "#{base_component_cache_key}/#{ReactOnRailsPro::Utils.bundle_hash}/" \
        "#{ReactOnRailsPro::Cache.dependencies_cache_key}"
    end
    let(:base_cache_key_without_prerender) do
      "#{base_component_cache_key}/#{ReactOnRailsPro::Cache.dependencies_cache_key}"
    end
    let(:base_js_eval_cache_key) do
      "ror_pro_rendered_html/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}"
    end

    describe "caching" do
      describe "ReactOnRailsProHelper.cached_react_component" do
        it "caches the content" do
          props = { a: 1, b: 2 }

          cached_react_component("App", cache_key: "cache-key") do
            props
          end

          expect(cache_data.keys)
            .to include(%r{/App/cache-key})
          expect(cache_data.first[1].value).to match(/div id="App-react-component"/)
        end

        it "uses 'cache_key' method if available" do
          props = { a: 1, b: 2 }
          active_model = double
          allow(active_model).to receive(:cache_key).and_return("xyz123")

          cached_react_component("App", cache_key: active_model) do
            props
          end

          expect(cache_data.keys).to include(/xyz123/)
        end

        it "doesn't call the block if content is cached" do
          cached_react_component("App", cache_key: "cache-key") do
            { a: 1, b: 2 }
          end

          expect do |props|
            cached_react_component("App", cache_key: "cache-key", &props)
          end.not_to yield_control
        end

        context "with multiple cache keys" do
          it "caches the content using cache keys" do
            props = { a: 1, b: 2 }
            cache_keys = %w[a b]

            cached_react_component("App", cache_key: cache_keys) do
              props
            end

            expect(cache_data.keys).to include(%r{/App/a/b})
            expect(cache_data.first[1].value).to match(/div id="App-react-component"/)
          end
        end

        context "with 'prerender' == true" do
          it "includes bundle hash in the cache key" do
            props = { a: 1, b: 2 }

            cached_react_component("App", cache_key: "cache-key", prerender: true) do
              props
            end

            expected_key = /#{ReactOnRailsPro::Utils.bundle_hash}/
            expect(cache_data.keys).to include(expected_key)
          end
        end

        context "when 'props' aren't passed in a block" do
          it "throws an error" do
            props = { a: 1, b: 2 }

            expect do
              cached_react_component("App", cache_key: "cache-key", props: props)
            end.to raise_error("Pass 'props' as a block if using caching")
          end
        end
      end

      describe "ReactOnRailsProHelper.cached_react_component_hash" do
        it "caches the content" do
          props = { helloWorldData: { name: "Mr. Server Side Rendering" } }

          cached_react_component_hash("ReactHelmetApp", cache_key: "cache-key") do
            props
          end

          expect(cache_data.keys[0]).to match(%r{#{base_cache_key_with_prerender}/ReactHelmetApp/cache-key})
          expect(cache_data.values[0].value).to match(/div id="ReactHelmetApp-react-component"/)
        end

        context "with prerender_caching off" do
          before { ReactOnRailsPro.configuration.prerender_caching = false }

          after { ReactOnRailsPro.configuration.prerender_caching = true }

          it "caches the content" do
            props = { helloWorldData: { name: "Mr. Server Side Rendering" } }

            cached_react_component_hash("ReactHelmetApp", cache_key: "cache-key") do
              props
            end

            expect(cache_data.keys[0]).to match(%r{#{base_cache_key_with_prerender}/ReactHelmetApp/cache-key})
            expect(cache_data.values[0].value).to match(/div id="ReactHelmetApp-react-component"/)
          end
        end

        context "with prerender_caching on" do
          it "creates only one cache entity" do
            props = { helloWorldData: { name: "Mr. Server Side Rendering" } }

            cached_react_component_hash("ReactHelmetApp", cache_key: "cache-key") do
              props
            end

            expect(cache_data.keys.count).to eq(1)
          end
        end
      end
    end
  end

  describe "html_streaming_react_component" do
    include StreamingTestHelpers

    let(:component_name) { "StreamAsyncComponents" }
    let(:props) { { helloWorldData: { name: "Mr. Server Side Rendering" } } }
    let(:component_options) { { prerender: true, trace: true, id: "#{component_name}-react-component-0" } }
    let(:chunks) do
      [
        { html: "<div>Chunk 1: Stream React Server Components</div>",
          consoleReplayScript: "<script>console.log.apply(console, " \
                               "['Chunk 1: Console Message'])</script>" },
        { html: "<div>Chunk 2: More content</div>",
          consoleReplayScript: "<script>console.log.apply(console, " \
                               "['Chunk 2: Console Message']);\n" \
                               "console.error.apply(console, " \
                               "['Chunk 2: Console Error']);</script>" },
        { html: "<div>Chunk 3: Final content</div>", consoleReplayScript: "" }
      ]
    end
    let(:chunks_read) { [] }
    let(:react_component_specification_tag) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" data-component-name="StreamAsyncComponents" data-trace="true" data-dom-id="StreamAsyncComponents-react-component-0">{"helloWorldData":{"name":"Mr. Server Side Rendering"}}</script>
      SCRIPT
    end
    let(:rails_context_tag) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" id="js-react-on-rails-context">{"railsEnv":"test","inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","rorVersion":"#{ReactOnRails::VERSION}","rorPro":true,"rorProVersion":"#{ReactOnRailsPro::VERSION}","href":"http://foobar.com/development","location":"/development","scheme":"http","host":"foobar.com","port":null,"pathname":"/development","search":null,"httpAcceptLanguage":"en","somethingUseful":null,"serverSide":false}</script>
      SCRIPT
    end
    let(:react_component_div_with_initial_chunk) do
      <<-HTML.strip
        <div id="StreamAsyncComponents-react-component-0">#{chunks.first[:html]}</div>
      HTML
    end

    def mock_request_and_response
      chunks_read.clear
      allow(ReactOnRailsPro::Request).to receive(:perform_request) do |_path, _form_data, &block|
        response = instance_double(Net::HTTPResponse, code: "200")
        allow(response).to receive(:read_body) do |&read_body_block|
          chunks.each do |chunk|
            chunks_read << chunk
            read_body_block.call(chunk.to_json)
          end
        end
        block.call(response)
        response
      end
    end

    describe "#stream_react_component" do
      before do
        # Initialize @rorp_rendering_fibers to mock the behavior of stream_view_containing_react_components.
        # This instance variable is normally set by stream_view_containing_react_components method.
        # By setting it here, we simulate that the view is being rendered using that method.
        # This setup is necessary because stream_react_component relies on @rorp_rendering_fibers
        # to function correctly within the streaming context.
        @rorp_rendering_fibers = []
        mock_request_and_response
      end

      it "returns the component shell that exist in the initial chunk with the consoleReplayScript" do
        initial_result = stream_react_component(component_name, props: props, **component_options)
        expect(initial_result).to include(react_component_div_with_initial_chunk)
        expect(initial_result).to include(chunks.first[:consoleReplayScript])
        expect(initial_result).not_to include("More content", "Final content")
        expect(chunks_read.count).to eq(1)
      end

      it "creates a fiber to read subsequent chunks" do
        stream_react_component(component_name, props: props, **component_options)
        expect(@rorp_rendering_fibers.count).to eq(1) # rubocop:disable RSpec/InstanceVariable
        fiber = @rorp_rendering_fibers.first # rubocop:disable RSpec/InstanceVariable
        expect(fiber).to be_alive

        second_result = fiber.resume
        # regex that matches the html and consoleReplayScript and allows for any amount of whitespace between them
        expect(second_result).to match(
          /#{Regexp.escape(chunks[1][:html])}\s+#{Regexp.escape(chunks[1][:consoleReplayScript])}/
        )
        expect(second_result).not_to include("Stream React Server Components", "Final content")
        expect(chunks_read.count).to eq(2)

        third_result = fiber.resume
        expect(third_result).to eq(chunks[2][:html].to_s)
        expect(third_result).not_to include("Stream React Server Components", "More content")
        expect(chunks_read.count).to eq(3)

        expect(fiber.resume).to be_nil
        expect(fiber).not_to be_alive
        expect(chunks_read.count).to eq(chunks.count)
      end
    end

    describe "stream_view_containing_react_components" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:mocked_stream) { instance_double(ActionController::Live::Buffer) }
      let(:written_chunks) { [] }

      before do
        written_chunks.clear
        # Mock the render_to_string method and make it calls stream_react_component
        # stream_view_containing_react_components assumes it renders a view containing calls to stream_react_component
        allow(self).to receive(:render_to_string) do
          render_result = stream_react_component(component_name, props: props, **component_options)
          <<-HTML
            <div>
              <h1>Header Rendered In View</h1>
              #{render_result}
            </div>
          HTML
        end

        allow(mocked_stream).to receive(:write) do |chunk|
          written_chunks << chunk
          # Ensures that any chunk received is written immediately to the stream
          expect(written_chunks.count).to eq(chunks_read.count) # rubocop:disable RSpec/ExpectInHook
        end
        allow(mocked_stream).to receive(:close)
        mocked_response = instance_double(ActionDispatch::Response)
        allow(mocked_response).to receive(:stream).and_return(mocked_stream)
        allow(self).to receive(:response).and_return(mocked_response)
        mock_request_and_response
      end

      it "writes the chunk to stream as soon as it is received" do
        stream_view_containing_react_components(template: "path/to/your/template")
        expect(self).to have_received(:render_to_string).once.with(template: "path/to/your/template")
        expect(chunks_read.count).to eq(chunks.count)
        expect(written_chunks.count).to eq(chunks.count)
        expect(mocked_stream).to have_received(:write).exactly(chunks.count).times
        expect(mocked_stream).to have_received(:close)
      end

      it "prepends the rails context to the first chunk only" do
        stream_view_containing_react_components(template: "path/to/your/template")
        initial_result = written_chunks.first
        expect(initial_result).to script_tag_be_included(rails_context_tag)

        # Check that the Rails context is before the first chunk
        rails_context_index = initial_result.index('id="js-react-on-rails-context"')
        first_chunk_index = initial_result.index(chunks.first[:html])
        expect(rails_context_index).to be < first_chunk_index

        # The following chunks should not include the Rails context
        written_chunks[1..].each do |chunk|
          expect(chunk).not_to include('id="js-react-on-rails-context"')
        end
      end

      it "prepends the component specification tag to the first chunk only" do
        stream_view_containing_react_components(template: "path/to/your/template")
        initial_result = written_chunks.first
        expect(initial_result).to script_tag_be_included(react_component_specification_tag)

        # The following chunks should not include the component specification tag
        written_chunks[1..].each do |chunk|
          expect(chunk).not_to include('class="js-react-on-rails-component"')
        end
      end

      it "renders the rails view content in the first chunk" do
        stream_view_containing_react_components(template: "path/to/your/template")
        initial_result = written_chunks.first
        expect(initial_result).to include("<h1>Header Rendered In View</h1>")
        written_chunks[1..].each do |chunk|
          expect(chunk).not_to include("<h1>Header Rendered In View</h1>")
        end
      end
    end
  end
end
