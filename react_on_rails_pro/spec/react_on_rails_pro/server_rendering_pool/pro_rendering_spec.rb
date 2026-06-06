# frozen_string_literal: true

require_relative "../spec_helper"

module ReactOnRailsPro
  module ServerRenderingPool
    RSpec.describe ProRendering do
      describe ".set_request_digest_on_render_options" do
        let(:logger_mock) { instance_double(ActiveSupport::Logger).as_null_object }
        let(:render_options_class) do
          Struct.new(:request_digest, keyword_init: true) do
            def random_dom_id?
              true
            end

            def react_component_name
              "CacheProbe"
            end

            def internal_option(_name)
              nil
            end

            def streaming?
              false
            end

            def prerender
              true
            end
          end
        end

        before do
          allow(Rails).to receive(:logger).and_return(logger_mock)
        end

        def request_digest_for(js_code)
          render_options = render_options_class.new

          described_class.set_request_digest_on_render_options(js_code, render_options)

          render_options.request_digest
        end

        def render_js(dom_node_id:, quote:, props: '{"name":"same"}')
          quoted_dom_node_id = quote == :single ? "'#{dom_node_id}'" : dom_node_id.to_json

          <<~JS
            return ReactOnRails['serverRenderReactComponent']({
              name: "CacheProbe",
              domNodeId: #{quoted_dom_node_id},
              props: #{props},
              trace: false,
              railsContext: {},
            });
          JS
        end

        it "ignores single-quoted random domNodeId values when calculating the request digest" do
          first_digest = request_digest_for(render_js(dom_node_id: "CacheProbe-react-component-1", quote: :single))
          second_digest = request_digest_for(render_js(dom_node_id: "CacheProbe-react-component-2", quote: :single))

          expect(first_digest).to eq(second_digest)
        end

        it "ignores double-quoted random domNodeId values when calculating the request digest" do
          first_digest = request_digest_for(render_js(dom_node_id: "CacheProbe-react-component-1", quote: :double))
          second_digest = request_digest_for(render_js(dom_node_id: "CacheProbe-react-component-2", quote: :double))

          expect(first_digest).to eq(second_digest)
        end

        it "still changes the request digest when non-random render input changes" do
          first_digest = request_digest_for(
            render_js(dom_node_id: "CacheProbe-react-component-1", quote: :double, props: '{"name":"first"}')
          )
          second_digest = request_digest_for(
            render_js(dom_node_id: "CacheProbe-react-component-1", quote: :double, props: '{"name":"second"}')
          )

          expect(first_digest).not_to eq(second_digest)
        end

        context "with prerender caching enabled" do
          let(:pool) do
            Class.new do
              def exec_server_render_js(_js_code, _render_options)
                { html: "rendered" }
              end
            end.new
          end
          let(:cache_store) do
            Class.new do
              def initialize
                @store = {}
              end

              def fetch(key)
                return @store[key] if @store.key?(key)

                @store[key] = yield
              end
            end.new
          end

          before do
            allow(pool).to receive(:exec_server_render_js).and_call_original
            allow(described_class).to receive(:pool).and_return(pool)
            allow(Rails).to receive(:cache).and_return(cache_store)
            allow(ReactOnRailsPro.configuration).to receive(:prerender_caching).and_return(true)
            allow(ReactOnRailsPro::Cache).to receive(:base_cache_key).and_return(%w[ror_pro_rendered_html test])
            allow(ReactOnRailsPro::Utils).to receive(:with_trace).and_yield
          end

          it "reuses the cached render for current double-quoted random domNodeId values" do
            described_class.exec_server_render_js(
              render_js(dom_node_id: "CacheProbe-react-component-1", quote: :double),
              render_options_class.new
            )
            described_class.exec_server_render_js(
              render_js(dom_node_id: "CacheProbe-react-component-2", quote: :double),
              render_options_class.new
            )

            expect(pool).to have_received(:exec_server_render_js).once
          end
        end
      end
    end
  end
end
