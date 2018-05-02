# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

describe ReactOnRailsProHelper, type: :helper do
  # In order to test the pro helper, we need to load the methods from the regular helper.
  # I couldn't see any easier way to do this.
  include ReactOnRails::Helper
  before do
    allow(self).to receive(:request) {
      OpenStruct.new(
        original_url: "http://foobar.com/development",
        env: { "HTTP_ACCEPT_LANGUAGE" => "en" }
      )
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
    '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip'\
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
  end

  let(:json_string_unsanitized) do
    "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
  end

  describe "#cached_react_component" do
    before { allow(SecureRandom).to receive(:uuid).and_return(0, 1, 2, 3) }

    # subject { creact_component("App", props: props) }
    #
    # let(:props) do
    #   { name: "My Test Name" }
    # end
    #
    # let(:react_component_div) do
    #   '<div id="App-react-component-0"></div>'
    # end
    #
    # let(:id) { "App-react-component-0" }
    #
    # let(:react_definition_script) do
    #   <<-SCRIPT.strip_heredoc
    #     <script type="application/json" class="js-react-on-rails-component" \
    #     data-component-name="App" data-dom-id="App-react-component-0">{"name":"My Test Name"}</script>
    #   SCRIPT
    # end
    #
    # let(:react_definition_script_no_params) do
    #   <<-SCRIPT.strip_heredoc
    #     <script type="application/json" class="js-react-on-rails-component" \
    #     data-component-name="App" data-dom-id="App-react-component-0">{}</script>
    #   SCRIPT
    # end

    describe "caching" do
      describe "ReactOnRailsProHeler.cached_react_component", :caching do
        it "caches the content" do
          props = { a: 1, b: 2 }
          cached_react_component("App", cache_key: "cache-key") do
            props
          end

          expect(cache_data.keys).to include(%r{react_on_rails/App/cache-key})
          expect(cache_data.first[1].value).to match(/div id="App-react-component-0"/)
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

            expect(cache_data.keys).to include(%r{react_on_rails/App/a/b})
            expect(cache_data.first[1].value).to match(/div id="App-react-component-0"/)
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

      describe "ReactOnRailsProHelper.cached_react_component_hash", :caching do
        it "caches the content" do
          props = { a: 1, b: 2 }
          cached_react_component_hash("ReactHelmetApp", cache_key: "cache-key", prerender: true) do
            props
          end

          expect(cache_data.keys).to include(%r{react_on_rails/ReactHelmetApp/cache-key})
          expect(cache_data.first[1].value["componentHtml"]).to match(/div id="ReactHelmetApp-react-component-0"/)
        end
      end

      context "without 'cache'", :caching do
        it "doesn't caches the content" do
          react_component("App", prerender: true)
          expect(cache_data.keys).to be_empty
        end
      end
    end
  end
end
