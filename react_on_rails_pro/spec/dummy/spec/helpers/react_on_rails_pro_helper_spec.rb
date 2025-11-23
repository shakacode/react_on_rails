# frozen_string_literal: true

require "async"
require "async/queue"
require "async/barrier"
require "rails_helper"
require "support/script_tag_utils"

RequestDetails = Struct.new(:original_url, :env)

# rubocop:disable RSpec/InstanceVariable

# This module is created to provide stub methods for `render_to_string` and `response`
# These methods will be mocked in the tests to prevent "<object> does not implement <method>" errors
# when these methods are called during testing.
module StreamingTestHelpers
  def render_to_string(*args); end
  def response; end
end

describe ReactOnRailsProHelper do
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

  describe "caching react_component", :caching do
    shared_examples "prerender caching behavior" do |enable_rsc_support:|
      around do |example|
        original_enable_rsc_support = ReactOnRailsPro.configuration.enable_rsc_support
        ReactOnRailsPro.configuration.enable_rsc_support = enable_rsc_support

        example.run
      ensure
        ReactOnRailsPro.configuration.enable_rsc_support = original_enable_rsc_support
      end

      context "when config.prerender_caching is true" do
        around do |example|
          original_prerender_caching = ReactOnRailsPro.configuration.prerender_caching
          ReactOnRailsPro.configuration.prerender_caching = true

          example.run
        ensure
          ReactOnRailsPro.configuration.prerender_caching = original_prerender_caching
        end

        it "caches the content" do
          props = { a: 1, b: 2 }

          render_result = react_component("RandomValue", props: props, prerender: true)
          # Ensure that the component is rendered correctly
          expect(render_result).to include("RandomValue:")

          expect(cache_data.keys.count).to eq(1)
        end

        it "doesn't rerender the component after the first render" do
          props = { a: 1, b: 2 }

          first_render_result = react_component("RandomValue", props: props, prerender: true)
          second_render_result = react_component("RandomValue", props: props, prerender: true)
          expect(first_render_result).to include("RandomValue:")
          expect(second_render_result).to include("RandomValue:")

          expect(cache_data.keys.count).to eq(1)
          # The first render will contain the rails context
          # So, we can't use `eq` to compare the results
          # We can use `include` to check if the second render result is included in the first render result
          expect(first_render_result).to include(second_render_result)
        end

        it "rerender the component if the props are different" do
          props = { a: 1, b: 2 }
          props2 = { a: 2, b: 3 }

          first_render_result = react_component("RandomValue", props: props, prerender: true)
          second_render_result = react_component("RandomValue", props: props2, prerender: true)

          expect(first_render_result).to include("RandomValue:")
          expect(second_render_result).to include("RandomValue:")

          expect(cache_data.keys.count).to eq(2)
          expect(first_render_result).not_to include(second_render_result)
        end
      end

      context "when config.prerender_caching is false" do
        around do |example|
          original_prerender_caching = ReactOnRailsPro.configuration.prerender_caching
          ReactOnRailsPro.configuration.prerender_caching = false

          example.run
        ensure
          ReactOnRailsPro.configuration.prerender_caching = original_prerender_caching
        end

        it "doesn't cache the content" do
          props = { a: 1, b: 2 }

          render_result = react_component("RandomValue", props: props, prerender: true)
          expect(render_result).to include("RandomValue:")

          expect(cache_data.keys.count).to eq(0)
        end

        it "rerenders the component even if the props are the same" do
          props = { a: 1, b: 2 }

          first_render_result = react_component("RandomValue", props: props, prerender: true)
          second_render_result = react_component("RandomValue", props: props, prerender: true)

          expect(first_render_result).to include("RandomValue:")
          expect(second_render_result).to include("RandomValue:")

          expect(cache_data.keys.count).to eq(0)
          expect(first_render_result).not_to include(second_render_result)
        end
      end
    end

    context "with RSC support enabled" do
      include_examples "prerender caching behavior", enable_rsc_support: true
    end

    context "with RSC support disabled" do
      include_examples "prerender caching behavior", enable_rsc_support: false
    end
  end

  describe "html_streaming_react_component" do
    include StreamingTestHelpers

    let(:component_name) { "TestingStreamableComponent" }
    let(:props) { { helloWorldData: { name: "Mr. Server Side Rendering" } } }
    let(:component_options) { { prerender: true, trace: true, id: "#{component_name}-react-component-0" } }
    let(:template_path) { "fake/path/because/render_to_string&response/are/mocked" }
    let(:chunks) do
      [
        { html: "<div>Chunk 1: Stream React Server Components</div>",
          consoleReplayScript: "console.log.apply(console, " \
                               "['Chunk 1: Console Message'])" },
        { html: "<div>Chunk 2: More content</div>",
          consoleReplayScript: "console.log.apply(console, " \
                               "['Chunk 2: Console Message']);\n" \
                               "console.error.apply(console, " \
                               "['Chunk 2: Console Error']);" },
        { html: "<div>Chunk 3: Final content</div>", consoleReplayScript: "" }
      ]
    end
    let(:chunks_read) { [] }
    let(:react_component_specification_tag) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json"
          id="js-react-on-rails-component-TestingStreamableComponent-react-component-0"
          class="js-react-on-rails-component"
          data-component-name="TestingStreamableComponent"
          data-trace="true"
          data-dom-id="TestingStreamableComponent-react-component-0"
          data-immediate-hydration="true"
        >{"helloWorldData":{"name":"Mr. Server Side Rendering"}}</script>
      SCRIPT
    end
    let(:rails_context_tag) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" id="js-react-on-rails-context">{"componentRegistryTimeout":5000,"railsEnv":"test","inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","rorVersion":"#{ReactOnRails::VERSION}","rorPro":true,"rorProVersion":"#{ReactOnRailsPro::VERSION}","rscPayloadGenerationUrlPath":"rsc_payload/","href":"http://foobar.com/development","location":"/development","scheme":"http","host":"foobar.com","port":null,"pathname":"/development","search":null,"httpAcceptLanguage":"en","somethingUseful":null,"serverSide":false}</script>
      SCRIPT
    end
    let(:react_component_div_with_initial_chunk) do
      <<-HTML.strip
        <div id="TestingStreamableComponent-react-component-0">#{chunks.first[:html]}</div>
      HTML
    end

    # mock_chunks can be an Async::Queue or an Array
    def mock_request_and_response(mock_chunks = chunks, count: 1)
      # Reset connection instance variables to ensure clean state for tests
      ReactOnRailsPro::Request.instance_variable_set(:@connection, nil)
      original_httpx_plugin = HTTPX.method(:plugin)
      allow(HTTPX).to receive(:plugin) do |*args|
        original_httpx_plugin.call(:mock_stream).plugin(*args)
      end
      clear_stream_mocks

      chunks_read.clear
      mock_streaming_response(%r{http://localhost:3800/bundles/[a-f0-9]{32}-test/render/[a-f0-9]{32}}, 200,
                              count: count) do |yielder|
        if mock_chunks.is_a?(Async::Queue)
          loop do
            chunk = mock_chunks.dequeue
            break if chunk.nil?

            chunks_read << chunk
            yielder.call("#{chunk.to_json}\n")
          end
        else
          mock_chunks.each do |chunk|
            chunks_read << chunk
            yielder.call("#{chunk.to_json}\n")
          end
        end
      end
    end

    describe "#stream_react_component" do
      around do |example|
        # Wrap each test in Sync block to provide async context
        Sync do
          # Initialize async primitives to mock the behavior of stream_view_containing_react_components.
          # These instance variables are normally set by stream_view_containing_react_components method.
          # By setting them here, we simulate that the view is being rendered using that method.
          # This setup is necessary because stream_react_component relies on @async_barrier and @main_output_queue
          # to function correctly within the streaming context.
          @async_barrier = Async::Barrier.new
          @main_output_queue = Async::Queue.new

          example.run
        end
      end

      it "returns the component shell that exist in the initial chunk with the consoleReplayScript" do
        mock_request_and_response
        initial_result = stream_react_component(component_name, props: props, **component_options)
        expect(initial_result).to include(react_component_div_with_initial_chunk)
        # consoleReplayScript is now wrapped in a script tag with id="consoleReplayLog"
        if chunks.first[:consoleReplayScript].present?
          script = chunks.first[:consoleReplayScript]
          wrapped = "<script id=\"consoleReplayLog\">#{script}</script>"
          expect(initial_result).to include(wrapped)
        end
        expect(initial_result).not_to include("More content", "Final content")
        # NOTE: With async architecture, chunks are consumed in background immediately,
        expect(chunks_read.count).to eq(3)
      end

      it "streams subsequent chunks to the output queue" do
        mock_request_and_response
        initial_result = stream_react_component(component_name, props: props, **component_options)

        # First chunk is returned synchronously
        expect(initial_result).to include(react_component_div_with_initial_chunk)

        # Wait for async task to complete
        @async_barrier.wait
        @main_output_queue.close

        # Subsequent chunks should be in the output queue
        collected_chunks = []
        while (chunk = @main_output_queue.dequeue)
          collected_chunks << chunk
        end

        # Should have received the remaining chunks (chunks 2 and 3)
        expect(collected_chunks.length).to eq(2)

        # Verify second chunk content
        script = chunks[1][:consoleReplayScript]
        wrapped = script.present? ? "<script id=\"consoleReplayLog\">#{script}</script>" : ""
        expect(collected_chunks[0]).to match(
          /#{Regexp.escape(chunks[1][:html])}\s+#{Regexp.escape(wrapped)}/
        )

        # Verify third chunk content
        expect(collected_chunks[1]).to eq(chunks[2][:html].to_s)
      end

      it "does not trim whitespaces from html" do
        first_chunk_string = +"  <div>Chunk 1: with whitespaces</div>  "
        chunks_with_whitespaces = [
          { html: first_chunk_string },
          { html: "\n\n\n<div>Chunk 2: with newlines</div>\n\n\n" },
          { html: "<div>Chunk 3: with tabs</div>\t\t\t" },
          { html: "\t\t\t<div>Chunk 4: with mixed whitespaces</div>  \n\n\n" }
        ].map { |chunk| chunk.merge(consoleReplayScript: "") }
        mock_request_and_response(chunks_with_whitespaces)

        initial_result = stream_react_component(component_name, props: props, **component_options)
        expect(initial_result).to include(chunks_with_whitespaces.first[:html])

        # Wait for async task to complete
        @async_barrier.wait
        @main_output_queue.close

        # Collect remaining chunks from queue
        collected_chunks = []
        while (chunk = @main_output_queue.dequeue)
          collected_chunks << chunk
        end

        # Verify whitespaces are preserved in all chunks
        expect(collected_chunks[0]).to include(chunks_with_whitespaces[1][:html])
        expect(collected_chunks[1]).to include(chunks_with_whitespaces[2][:html])
        expect(collected_chunks[2]).to include(chunks_with_whitespaces[3][:html])
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
        end
        allow(mocked_stream).to receive(:close)
        mocked_response = instance_double(ActionDispatch::Response)
        allow(mocked_response).to receive(:stream).and_return(mocked_stream)
        allow(self).to receive(:response).and_return(mocked_response)
      end

      def execute_stream_view_containing_react_components
        queue = Async::Queue.new
        mock_request_and_response(queue)

        Sync do |parent|
          parent.async { stream_view_containing_react_components(template: template_path) }

          chunks_to_write = chunks.dup
          while (chunk = chunks_to_write.shift)
            queue.enqueue(chunk)
            sleep 0.05

            # Ensures that any chunk received is written immediately to the stream
            expect(written_chunks.count).to eq(chunks_read.count)
          end
          queue.close
          sleep 0.05
        end
      end

      it "writes the chunk to stream as soon as it is received" do
        execute_stream_view_containing_react_components
        expect(self).to have_received(:render_to_string).once.with(template: template_path)
        expect(chunks_read.count).to eq(chunks.count)
        expect(written_chunks.count).to eq(chunks.count)
        expect(mocked_stream).to have_received(:write).exactly(chunks.count).times
        expect(mocked_stream).to have_received(:close)
      end

      it "prepends the rails context to the first chunk only" do
        execute_stream_view_containing_react_components
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
        execute_stream_view_containing_react_components
        initial_result = written_chunks.first
        expect(initial_result).to script_tag_be_included(react_component_specification_tag)

        # The following chunks should not include the component specification tag
        written_chunks[1..].each do |chunk|
          expect(chunk).not_to include('class="js-react-on-rails-component"')
        end
      end

      it "renders the rails view content in the first chunk" do
        execute_stream_view_containing_react_components
        initial_result = written_chunks.first
        expect(initial_result).to include("<h1>Header Rendered In View</h1>")
        written_chunks[1..].each do |chunk|
          expect(chunk).not_to include("<h1>Header Rendered In View</h1>")
        end
      end
    end

    describe "#cached_stream_react_component", :caching do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:mocked_stream) { instance_double(ActionController::Live::Buffer) }
      let(:written_chunks) { [] }

      around do |example|
        original_prerender_caching = ReactOnRailsPro.configuration.prerender_caching
        ReactOnRailsPro.configuration.prerender_caching = true
        Rails.cache.clear
        example.run
      ensure
        ReactOnRailsPro.configuration.prerender_caching = original_prerender_caching
        Rails.cache.clear
      end

      before do
        written_chunks.clear
        allow(mocked_stream).to receive(:write) { |chunk| written_chunks << chunk }
        allow(mocked_stream).to receive(:close)
        mocked_response = instance_double(ActionDispatch::Response)
        allow(mocked_response).to receive(:stream).and_return(mocked_stream)
        allow(self).to receive(:response).and_return(mocked_response)
      end

      def render_with_cached_stream(**opts)
        stub_render_with_cached_stream(
          cache_key: ["stream-cache-spec", component_name],
          props: props,
          **opts
        )
      end

      def render_with_cached_stream_changed_props(**opts)
        stub_render_with_cached_stream(
          cache_key: ["stream-cache-spec", component_name, "changed"],
          props: props.merge(extra: "changed"),
          **opts
        )
      end

      def stub_render_with_cached_stream(cache_key:, props:, **opts)
        allow(self).to receive(:render_to_string) do
          render_result = cached_stream_react_component(
            component_name,
            cache_key: cache_key,
            id: "#{component_name}-react-component-0",
            trace: true,
            cache_options: { expires_in: 60 },
            **opts
          ) do
            props
          end
          <<-HTML
            <div>
              <h1>Header Rendered In View</h1>
              #{render_result}
            </div>
          HTML
        end
      end

      def reset_stream_buffers
        written_chunks.clear
        chunks_read.clear
      end

      def run_stream
        stream_view_containing_react_components(template: template_path)
        written_chunks.dup
      end

      it "serves MISS then HIT with identical chunks and no second Node call" do
        mock_request_and_response
        render_with_cached_stream

        expect(Rails.cache)
          .to receive(:write).with(anything, kind_of(Array), hash_including(expires_in: 60)).and_call_original

        # First render (MISS → write-through)
        first_run_chunks = run_stream
        expect(chunks_read.count).to eq(chunks.count)
        expect(first_run_chunks.first).to include("<h1>Header Rendered In View</h1>")

        # Second render (HIT → served from cache, no Node call; no new HTTPX chunks)
        reset_stream_buffers
        # Reset rails context flag to simulate a fresh request lifecycle
        @rendered_rails_context = nil
        second_run_chunks = run_stream
        expect(chunks_read.count).to eq(0)
        expect(second_run_chunks).to eq(first_run_chunks)
      end

      it "respects skip_prerender_cache and does not write or hit cache" do
        mock_request_and_response(count: 3)
        # Disable view-level caching for this run via conditional
        render_with_cached_stream(if: false)

        expect(Rails.cache).not_to receive(:write)

        # First render
        run_stream
        first_call_count = chunks_read.count
        expect(first_call_count).to eq(chunks.count)

        # Second render (still goes to Node)
        reset_stream_buffers
        run_stream
        reset_stream_buffers
        run_stream
        expect(chunks_read.count).to eq(chunks.count)
      end

      it "invalidates cache when props change" do
        # First run with base props
        mock_request_and_response(count: 2)
        render_with_cached_stream
        first_run_chunks = run_stream

        # Second run with different props triggers MISS
        reset_stream_buffers
        render_with_cached_stream_changed_props
        second_run_chunks = run_stream

        expect(second_run_chunks).not_to eq(first_run_chunks)
      end

      it "doesn't call the props block on cache HIT" do
        mock_request_and_response
        render_with_cached_stream

        # Prime the cache
        run_stream
        reset_stream_buffers

        # Second call should not yield the block
        expect do |props_block|
          stub_render_with_cached_stream(
            cache_key: ["stream-cache-spec", component_name],
            props: props,
            &props_block
          )
          run_stream
        end.not_to yield_control
      end

      it "respects conditional caching with :if option" do
        mock_request_and_response(count: 2)

        # With if: false, caching should be disabled - both calls hit Node renderer
        render_with_cached_stream(if: false)
        first_run_chunks = run_stream
        expect(chunks_read.count).to eq(chunks.count)

        reset_stream_buffers
        @rendered_rails_context = nil
        render_with_cached_stream(if: false)
        second_run_chunks = run_stream
        expect(chunks_read.count).to eq(chunks.count) # Both calls went to Node

        expect(second_run_chunks).to eq(first_run_chunks) # Same template/props, same result
      end
    end

    describe "cached_stream_react_component integration with RandomValue", :caching do
      around do |example|
        original_prerender_caching = ReactOnRailsPro.configuration.prerender_caching
        ReactOnRailsPro.configuration.prerender_caching = true
        Rails.cache.clear
        example.run
      ensure
        ReactOnRailsPro.configuration.prerender_caching = original_prerender_caching
        Rails.cache.clear
      end

      # we need this setup because we can't use the helper outside of stream_view_containing_react_components
      def render_cached_random_value(cache_key)
        # Streaming helpers require this context normally provided by stream_view_containing_react_components
        result = nil
        Sync do
          @async_barrier = Async::Barrier.new
          @main_output_queue = Async::Queue.new

          result = cached_stream_react_component("RandomValue", cache_key: cache_key,
                                                                id: "RandomValue-react-component-0") do
            { a: 1, b: 2 }
          end

          # Complete the streaming lifecycle to trigger cache writes
          @async_barrier.wait
          @main_output_queue.close

          # Drain the queue
          while @main_output_queue.dequeue
            # Just consume all remaining chunks
          end
        end

        result
      end

      it "serves same RandomValue on cache HIT with identical cache key" do
        first_result = render_cached_random_value("stable_key")
        first_random_value = first_result[/RandomValue:\s*<!--\s*-->([\d.]+)/, 1]
        expect(first_random_value).to be_present

        second_result = render_cached_random_value("stable_key")
        second_random_value = second_result[/RandomValue:\s*<!--\s*-->([\d.]+)/, 1]

        expect(second_random_value).to eq(first_random_value)
      end

      it "serves different values on cache MISS with different cache keys" do
        first_result = render_cached_random_value("key_one")
        first_random_value = first_result[/RandomValue:\s*<!--\s*-->([\d.]+)/, 1]

        second_result = render_cached_random_value("key_two")
        second_random_value = second_result[/RandomValue:\s*<!--\s*-->([\d.]+)/, 1]

        expect(second_random_value).not_to eq(first_random_value)
      end
    end
  end

  describe "attribution comment in stream_react_component" do
    include StreamingTestHelpers

    let(:component_name) { "TestComponent" }
    let(:props) { { test: "data" } }
    let(:component_options) { { prerender: true, id: "#{component_name}-react-component-0" } }
    let(:chunks) do
      [
        { html: "<div>Test Content</div>", consoleReplayScript: "" }
      ]
    end

    around do |example|
      Sync do
        @async_barrier = Async::Barrier.new
        @main_output_queue = Async::Queue.new
        example.run
      end
    end

    before do
      ReactOnRailsPro::Request.instance_variable_set(:@connection, nil)
      original_httpx_plugin = HTTPX.method(:plugin)
      allow(HTTPX).to receive(:plugin) do |*args|
        original_httpx_plugin.call(:mock_stream).plugin(*args)
      end
      clear_stream_mocks

      mock_streaming_response(%r{http://localhost:3800/bundles/[a-f0-9]{32}-test/render/[a-f0-9]{32}}, 200,
                              count: 1) do |yielder|
        chunks.each do |chunk|
          yielder.call("#{chunk.to_json}\n")
        end
      end
    end

    it "includes the Pro attribution comment in the rendered output" do
      result = stream_react_component(component_name, props: props, **component_options)
      expect(result).to include("<!-- Powered by React on Rails Pro (c) ShakaCode")
    end

    it "includes the attribution comment only once" do
      result = stream_react_component(component_name, props: props, **component_options)
      comment_count = result.scan("<!-- Powered by React on Rails Pro").length
      expect(comment_count).to eq(1)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
