# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRails::ExecJSRenderingStrategy do
  subject(:strategy) { described_class.new }

  describe "#execute" do
    let(:render_options) do
      instance_double(
        ReactOnRails::ReactComponent::RenderOptions,
        dom_id: "App-react-component-uuid",
        trace: false,
        streaming?: false,
        logging_on_server: false
      )
    end

    let(:render_request) do
      instance_double(ReactOnRails::RenderRequest,
                      render_options: render_options,
                      to_js: "(function() { return '{}'; })()")
    end

    let(:expected_result) { { "html" => "<div>Hello</div>", "consoleReplayScript" => "" } }

    before do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to receive(:exec_server_render_js)
        .and_return(expected_result)
    end

    it "builds JS from the render request and delegates to RubyEmbeddedJavaScript" do
      result = strategy.execute(render_request)

      expect(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to have_received(:exec_server_render_js)
        .with("(function() { return '{}'; })()", render_options)
      expect(result).to eq(expected_result)
    end
  end

  describe "#execute_js" do
    let(:render_options) { instance_double(ReactOnRails::ReactComponent::RenderOptions) }
    let(:expected_result) { { "html" => "result", "consoleReplayScript" => "" } }

    before do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to receive(:exec_server_render_js)
        .and_return(expected_result)
    end

    it "delegates raw JS to RubyEmbeddedJavaScript" do
      result = strategy.execute_js("var x = 1;", render_options)

      expect(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript)
        .to have_received(:exec_server_render_js)
        .with("var x = 1;", render_options)
      expect(result).to eq(expected_result)
    end
  end

  describe "#reset" do
    it "delegates to RubyEmbeddedJavaScript.reset_pool" do
      allow(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript).to receive(:reset_pool)

      strategy.reset

      expect(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript).to have_received(:reset_pool)
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
