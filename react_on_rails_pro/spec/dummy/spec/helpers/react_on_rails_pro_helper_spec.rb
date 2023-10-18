# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

RequestDetails = Struct.new(:original_url, :env)

def cache_data
  Rails.cache.instance_variable_get(:@data)
end

describe ReactOnRailsProHelper, type: :helper do
  # In order to test the pro helper, we need to load the methods from the regular helper.
  # I couldn't see any easier way to do this.
  include ReactOnRails::Helper
  include Webpacker::Helper
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
          expect(cache_data.values[0].value["componentHtml"]).to match(/div id="ReactHelmetApp-react-component"/)
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
            expect(cache_data.values[0].value["componentHtml"]).to match(/div id="ReactHelmetApp-react-component"/)
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
end
