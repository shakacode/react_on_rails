# frozen_string_literal: true

require_relative "../spec_helper"

module ReactOnRailsPro
  module ServerRenderingPool
    RSpec.describe NodeRenderingPool do
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
        allow(described_class).to receive(:server_bundle_hash).and_return("server123")
        allow(described_class).to receive(:rsc_bundle_hash).and_return("rsc456")
      end

      describe ".prepare_incremental_render_path" do
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
              .with(expected_path, js_code, async_props_block: async_props_block, is_rsc_payload: false)
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
