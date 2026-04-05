# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool do
  describe ".eval_js" do
    let(:render_options) { instance_double(ReactOnRails::ReactComponent::RenderOptions) }
    let(:render_path) { "/bundles/123/render/abc" }
    let(:response_body) { 'Invalid "renderingRequest" field in render request.' }
    let(:response) do
      instance_double(HTTPX::Response, status: ReactOnRailsPro::STATUS_BAD_REQUEST, body: response_body)
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
end
