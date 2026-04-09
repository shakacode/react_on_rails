# frozen_string_literal: true

require_relative "spec_helper"

describe ReactOnRails::RenderRequest do
  subject(:render_request) do
    described_class.new(
      component_name: "MyComponent",
      props: { name: "World" },
      rails_context: rails_context,
      store_initializations: store_initializations,
      render_options: render_options
    )
  end

  let(:render_options) do
    instance_double(
      ReactOnRails::ReactComponent::RenderOptions,
      dom_id: "MyComponent-react-component-123",
      prerender: true,
      streaming?: false,
      rsc_payload_streaming?: false,
      trace: true
    )
  end

  let(:rails_context) { { railsEnv: "test", rorVersion: "16.0.0" } }
  let(:store_initializations) { "ReactOnRails.clearHydratedStores();" }

  describe "#component_name" do
    it "returns the component name" do
      expect(render_request.component_name).to eq("MyComponent")
    end
  end

  describe "#props" do
    it "returns the props" do
      expect(render_request.props).to eq(name: "World")
    end
  end

  describe "#dom_id" do
    it "delegates to render_options" do
      expect(render_request.dom_id).to eq("MyComponent-react-component-123")
    end
  end

  describe "#streaming?" do
    it "delegates to render_options" do
      expect(render_request.streaming?).to be(false)
    end
  end

  describe "#rsc_payload_streaming?" do
    it "delegates to render_options" do
      expect(render_request.rsc_payload_streaming?).to be(false)
    end
  end

  describe "#props_string" do
    it "returns JSON string of props" do
      expect(render_request.props_string).to eq('{"name":"World"}')
    end

    context "when props is already a string" do
      subject(:render_request) do
        described_class.new(
          component_name: "MyComponent",
          props: '{"name":"World"}',
          rails_context: rails_context,
          store_initializations: store_initializations,
          render_options: render_options
        )
      end

      it "returns the string as-is" do
        expect(render_request.props_string).to eq('{"name":"World"}')
      end
    end

    context "with unicode line separators" do
      subject(:render_request) do
        described_class.new(
          component_name: "MyComponent",
          props: { text: "hello\u2028world\u2029" },
          rails_context: rails_context,
          store_initializations: store_initializations,
          render_options: render_options
        )
      end

      it "escapes unicode line/paragraph separators" do
        result = render_request.props_string
        expect(result).not_to include("\u2028")
        expect(result).not_to include("\u2029")
        expect(result).to include('\u2028')
        expect(result).to include('\u2029')
      end
    end
  end

  describe "#rails_context_json" do
    it "returns JSON string of rails context" do
      json = render_request.rails_context_json
      parsed = JSON.parse(json)
      expect(parsed["railsEnv"]).to eq("test")
      expect(parsed["rorVersion"]).to eq("16.0.0")
    end
  end

  describe "#to_js" do
    before do
      allow(ReactOnRails.configuration).to receive(:server_bundle_js_file).and_return("server-bundle.js")
    end

    it "returns JavaScript code from the configured builder" do
      js = render_request.to_js
      expect(js).to include("ReactOnRails.serverRenderReactComponent")
      expect(js).to include('"MyComponent"')
      expect(js).to include("MyComponent-react-component-123")
    end

    context "when server_bundle_js_file is blank" do
      before do
        allow(ReactOnRails.configuration).to receive(:server_bundle_js_file).and_return("")
      end

      it "raises an error" do
        expect { render_request.to_js }.to raise_error(
          ReactOnRails::Error,
          /server_bundle_js_file/
        )
      end
    end
  end
end
