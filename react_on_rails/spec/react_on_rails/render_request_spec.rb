# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRails::RenderRequest do
  subject(:render_request) do
    described_class.new(
      component_name: "MyComponent",
      props_string: '{"name":"World"}',
      rails_context: '{"railsEnv":"test"}',
      store_initializations: "  ReactOnRails.clearHydratedStores();\n",
      render_options: render_options
    )
  end

  let(:render_options) do
    instance_double(
      ReactOnRails::ReactComponent::RenderOptions,
      dom_id: "MyComponent-react-component-abc123",
      streaming?: false,
      trace: true
    )
  end

  describe "#initialize" do
    it "stores component_name" do
      expect(render_request.component_name).to eq("MyComponent")
    end

    it "stores props_string" do
      expect(render_request.props_string).to eq('{"name":"World"}')
    end

    it "stores rails_context" do
      expect(render_request.rails_context).to eq('{"railsEnv":"test"}')
    end

    it "stores store_initializations" do
      expect(render_request.store_initializations).to eq("  ReactOnRails.clearHydratedStores();\n")
    end

    it "stores render_options" do
      expect(render_request.render_options).to eq(render_options)
    end
  end

  describe "#dom_id" do
    it "delegates to render_options" do
      expect(render_request.dom_id).to eq("MyComponent-react-component-abc123")
    end
  end

  describe "#streaming?" do
    it "delegates to render_options" do
      expect(render_request.streaming?).to be(false)
    end
  end

  describe "#trace?" do
    it "delegates to render_options" do
      expect(render_request.trace?).to be(true)
    end
  end

  describe "#to_js" do
    let(:mock_builder) { instance_double(ReactOnRails::JsCodeBuilder) }

    before do
      allow(ReactOnRails).to receive(:js_code_builder).and_return(mock_builder)
      allow(mock_builder).to receive(:build).with(render_request).and_return("(function() { /* js */ })()")
    end

    it "delegates to the configured js_code_builder" do
      result = render_request.to_js
      expect(mock_builder).to have_received(:build).with(render_request)
      expect(result).to eq("(function() { /* js */ })()")
    end
  end
end
