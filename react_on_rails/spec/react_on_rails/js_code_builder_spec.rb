# frozen_string_literal: true

require_relative "spec_helper"

describe ReactOnRails::JsCodeBuilder do
  subject(:builder) { described_class.new }

  let(:render_options) do
    instance_double(
      ReactOnRails::ReactComponent::RenderOptions,
      dom_id: "HelloWorld-react-component-abc",
      prerender: true,
      streaming?: false,
      trace: true
    )
  end

  let(:render_request) do
    instance_double(
      ReactOnRails::RenderRequest,
      component_name: "HelloWorld",
      dom_id: "HelloWorld-react-component-abc",
      props_string: '{"greeting":"Hi"}',
      rails_context_json: '{"railsEnv":"test"}',
      store_initializations: "ReactOnRails.clearHydratedStores();",
      render_options: render_options
    )
  end

  describe "#build" do
    it "returns a JavaScript IIFE" do
      js = builder.build(render_request)
      expect(js).to start_with("(function() {")
      expect(js).to end_with("})()")
    end

    it "includes railsContext setup" do
      js = builder.build(render_request)
      expect(js).to include('var railsContext = {"railsEnv":"test"};')
    end

    it "includes store initializations" do
      js = builder.build(render_request)
      expect(js).to include("ReactOnRails.clearHydratedStores();")
    end

    it "includes props setup" do
      js = builder.build(render_request)
      expect(js).to include('var props = {"greeting":"Hi"};')
    end

    it "includes the render call with correct component name" do
      js = builder.build(render_request)
      expect(js).to include("ReactOnRails.serverRenderReactComponent")
      expect(js).to include('"HelloWorld"')
    end

    it "includes the dom_id in the render call" do
      js = builder.build(render_request)
      expect(js).to include('"HelloWorld-react-component-abc"')
    end

    it "includes trace option" do
      js = builder.build(render_request)
      expect(js).to include("trace: true")
    end

    context "with nil store initializations" do
      let(:render_request) do
        instance_double(
          ReactOnRails::RenderRequest,
          component_name: "HelloWorld",
          dom_id: "HelloWorld-react-component-abc",
          props_string: '{"greeting":"Hi"}',
          rails_context_json: '{"railsEnv":"test"}',
          store_initializations: nil,
          render_options: render_options
        )
      end

      it "handles nil store initializations gracefully" do
        js = builder.build(render_request)
        expect(js).to include("ReactOnRails.serverRenderReactComponent")
      end
    end
  end
end
