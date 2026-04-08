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
                      component_name: "App",
                      props_string: '{"data":"value"}',
                      rails_context: '{"railsEnv":"test"}',
                      store_initializations: "",
                      render_options: render_options)
    end

    let(:expected_result) { { "html" => "<div>Hello</div>", "consoleReplayScript" => "" } }

    before do
      allow(ReactOnRails::ServerRenderingJsCode)
        .to receive(:server_rendering_component_js_code)
        .and_return("(function() { return '{}'; })()")
      allow(ReactOnRails::ServerRenderingPool)
        .to receive(:server_render_js_with_console_logging)
        .and_return(expected_result)
    end

    it "generates JS via ServerRenderingJsCode and executes via ServerRenderingPool" do
      result = strategy.execute(render_request)

      expect(ReactOnRails::ServerRenderingJsCode)
        .to have_received(:server_rendering_component_js_code)
        .with(
          props_string: '{"data":"value"}',
          rails_context: '{"railsEnv":"test"}',
          redux_stores: "",
          react_component_name: "App",
          render_options: render_options
        )
      expect(ReactOnRails::ServerRenderingPool)
        .to have_received(:server_render_js_with_console_logging)
        .with("(function() { return '{}'; })()", render_options)
      expect(result).to eq(expected_result)
    end
  end

  describe "#execute_js" do
    let(:render_options) { instance_double(ReactOnRails::ReactComponent::RenderOptions) }
    let(:expected_result) { { "html" => "result", "consoleReplayScript" => "" } }

    before do
      allow(ReactOnRails::ServerRenderingPool)
        .to receive(:server_render_js_with_console_logging)
        .and_return(expected_result)
    end

    it "delegates raw JS to ServerRenderingPool" do
      result = strategy.execute_js("var x = 1;", render_options)

      expect(ReactOnRails::ServerRenderingPool)
        .to have_received(:server_render_js_with_console_logging)
        .with("var x = 1;", render_options)
      expect(result).to eq(expected_result)
    end
  end

  describe "#reset" do
    it "delegates to ServerRenderingPool.reset_pool" do
      allow(ReactOnRails::ServerRenderingPool).to receive(:reset_pool)

      strategy.reset

      expect(ReactOnRails::ServerRenderingPool).to have_received(:reset_pool)
    end
  end

  describe "#reset_if_bundle_changed" do
    it "delegates to ServerRenderingPool.reset_pool_if_server_bundle_was_modified" do
      allow(ReactOnRails::ServerRenderingPool)
        .to receive(:reset_pool_if_server_bundle_was_modified)

      strategy.reset_if_bundle_changed

      expect(ReactOnRails::ServerRenderingPool)
        .to have_received(:reset_pool_if_server_bundle_was_modified)
    end
  end
end
