# frozen_string_literal: true

require_relative "../spec_helper"

module ReactOnRailsPro
  module ServerRenderingPool
    RSpec.describe NodeRenderingPool do
      describe ".eval_js" do
        let(:render_options) { instance_double(ReactOnRails::ReactComponent::RenderOptions) }
        let(:render_path) { "/bundles/123/render/abc" }
        let(:response_body) { 'Invalid "renderingRequest" field in render request.' }
        let(:response) do
          instance_double(ReactOnRailsPro::RendererHttpClient::Response,
                          status: ReactOnRailsPro::STATUS_BAD_REQUEST, body: response_body)
        end

        before do
          allow(described_class).to receive(:prepare_render_path).and_return(render_path)
          allow(ReactOnRailsPro::Request).to receive(:render_code)
            .with(render_path, "console.log('x')", false)
            .and_return(response)
          allow(ReactOnRailsPro.configuration).to receive(:renderer_use_fallback_exec_js).and_return(false)
        end

        it "raises a renderer bad request error message when renderer responds with 400" do
          expect do
            described_class.eval_js("console.log('x')", render_options)
          end.to raise_error(
            ReactOnRailsPro::Error,
            /Renderer rejected malformed request or hit an unhandled VM error: 400:\n#{Regexp.escape(response_body)}/
          )
        end
      end

      describe ".prepare_incremental_render_path" do
        let(:js_code) { "console.log('test');" }
        let(:render_options) do
          instance_double(
            ReactOnRails::ReactComponent::RenderOptions,
            request_digest: "abc123",
            rsc_payload_streaming?: false
          )
        end

        before do
          allow(ReactOnRailsPro::ServerRenderingPool::ProRendering)
            .to receive(:set_request_digest_on_render_options)
          allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(false)
          allow(described_class).to receive_messages(server_bundle_hash: "server123", rsc_bundle_hash: "rsc456")
        end

        it "returns path with incremental-render endpoint" do
          path = described_class.prepare_incremental_render_path(js_code, render_options)

          expect(path).to eq("/bundles/server123/incremental-render/abc123")
        end

        context "when RSC support is enabled and rendering RSC payload" do
          before do
            allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(true)
            allow(render_options).to receive(:rsc_payload_streaming?).and_return(true)
          end

          it "uses RSC bundle hash instead of server bundle hash" do
            path = described_class.prepare_incremental_render_path(js_code, render_options)

            expect(path).to eq("/bundles/rsc456/incremental-render/abc123")
          end
        end
      end

      describe ".eval_streaming_js" do
        let(:js_code) { "console.log('test');" }

        before do
          allow(ReactOnRailsPro::ServerRenderingPool::ProRendering)
            .to receive(:set_request_digest_on_render_options)
          allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(false)
          allow(described_class).to receive_messages(server_bundle_hash: "server123", rsc_bundle_hash: "rsc456")
        end

        context "when async_props_block is present in render_options" do
          let(:async_props_block) { proc { { data: "async_data" } } }
          let(:render_options) do
            instance_double(
              ReactOnRails::ReactComponent::RenderOptions,
              rsc_payload_streaming?: false,
              internal_option: async_props_block
            )
          end

          it "calls prepare_incremental_render_path and render_code_with_incremental_updates" do
            expected_path = "/bundles/server123/incremental-render/abc123"
            allow(described_class).to receive(:prepare_incremental_render_path)
              .with(js_code, render_options)
              .and_return(expected_path)
            allow(ReactOnRailsPro::Request).to receive(:render_code_with_incremental_updates)

            described_class.eval_streaming_js(js_code, render_options)

            expect(described_class).to have_received(:prepare_incremental_render_path)
              .with(js_code, render_options)
            expect(ReactOnRailsPro::Request).to have_received(:render_code_with_incremental_updates)
              .with(expected_path, js_code, async_props_block: async_props_block)
          end
        end

        context "when async_props_block is NOT present" do
          let(:render_options) do
            instance_double(
              ReactOnRails::ReactComponent::RenderOptions,
              rsc_payload_streaming?: false,
              internal_option: nil
            )
          end

          it "calls prepare_render_path and render_code_as_stream" do
            expected_path = "/bundles/server123/render/abc123"
            allow(described_class).to receive(:prepare_render_path)
              .with(js_code, render_options)
              .and_return(expected_path)
            allow(ReactOnRailsPro::Request).to receive(:render_code_as_stream)

            described_class.eval_streaming_js(js_code, render_options)

            expect(described_class).to have_received(:prepare_render_path)
              .with(js_code, render_options)
            expect(ReactOnRailsPro::Request).to have_received(:render_code_as_stream)
              .with(expected_path, js_code, is_rsc_payload: false)
          end
        end
      end
    end
  end
end
