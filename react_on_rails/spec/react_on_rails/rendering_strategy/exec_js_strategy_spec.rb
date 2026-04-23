# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::RenderingStrategy::ExecJsStrategy do
  subject(:strategy) { described_class.new }

  it "includes the RenderingStrategy module" do
    expect(strategy).to be_a(ReactOnRails::RenderingStrategy)
  end

  describe "#execute" do
    let(:render_options) do
      instance_double(
        ReactOnRails::ReactComponent::RenderOptions,
        dom_id: "App-react-component-1",
        prerender: true,
        streaming?: false,
        trace: false
      )
    end

    let(:render_request) do
      instance_double(
        ReactOnRails::RenderRequest,
        to_js: "(function() { return 'test'; })()",
        render_options: render_options
      )
    end

    let(:expected_result) { { "html" => "<div>Hello</div>", "consoleReplayScript" => "", "hasErrors" => false } }

    it "delegates to RubyEmbeddedJavaScript.exec_server_render_js" do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to receive(:exec_server_render_js)
        .with("(function() { return 'test'; })()", render_options)
        .and_return(expected_result)

      result = strategy.execute(render_request)
      expect(result).to eq(expected_result)
    end
  end

  describe "#reset" do
    it "delegates to RubyEmbeddedJavaScript.reset_pool" do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to receive(:reset_pool)

      strategy.reset

      expect(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to have_received(:reset_pool)
    end
  end

  describe "#reset_if_bundle_changed" do
    it "delegates to RubyEmbeddedJavaScript.reset_pool_if_server_bundle_was_modified" do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to receive(:reset_pool_if_server_bundle_was_modified)

      strategy.reset_if_bundle_changed

      expect(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to have_received(:reset_pool_if_server_bundle_was_modified)
    end
  end
end
