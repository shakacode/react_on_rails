# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRails::JsCodeBuilder do
  subject(:builder) { described_class.new }

  let(:render_options) do
    instance_double(
      ReactOnRails::ReactComponent::RenderOptions,
      dom_id: "HelloWorld-react-component-uuid",
      trace: true
    )
  end

  let(:render_request) do
    ReactOnRails::RenderRequest.new(
      component_name: "HelloWorld",
      props_string: '{"name":"World"}',
      rails_context: '{"railsEnv":"test"}',
      store_initializations: "  ReactOnRails.clearHydratedStores();\n",
      render_options: render_options
    )
  end

  describe "#build" do
    subject(:js_output) { builder.build(render_request) }

    it "returns a JavaScript IIFE" do
      expect(js_output).to include("(function() {")
      expect(js_output.strip).to end_with("})()")
    end

    it "includes railsContext variable declaration" do
      expect(js_output).to include('var railsContext = {"railsEnv":"test"};')
    end

    it "includes store initializations" do
      expect(js_output).to include("ReactOnRails.clearHydratedStores();")
    end

    it "includes props variable declaration" do
      expect(js_output).to include('var props = {"name":"World"};')
    end

    it "includes serverRenderReactComponent call with correct component name" do
      expect(js_output).to include('name: "HelloWorld"')
    end

    it "includes correct domNodeId" do
      expect(js_output).to include('domNodeId: "HelloWorld-react-component-uuid"')
    end

    it "includes trace setting" do
      expect(js_output).to include("trace: true")
    end

    it "passes railsContext to the render call" do
      expect(js_output).to include("railsContext: railsContext")
    end

    it "returns the result of serverRenderReactComponent" do
      expect(js_output).to include("return ReactOnRails.serverRenderReactComponent(")
    end
  end

  describe "#build without store initializations" do
    let(:render_request_no_stores) do
      ReactOnRails::RenderRequest.new(
        component_name: "SimpleComponent",
        props_string: "{}",
        rails_context: '{"railsEnv":"test"}',
        store_initializations: "",
        render_options: render_options
      )
    end

    it "still produces valid JS" do
      js_output = builder.build(render_request_no_stores)
      expect(js_output).to include("(function() {")
      expect(js_output).to include("var railsContext =")
      expect(js_output).to include("var props =")
      expect(js_output).to include("return ReactOnRails.serverRenderReactComponent(")
    end
  end
end
