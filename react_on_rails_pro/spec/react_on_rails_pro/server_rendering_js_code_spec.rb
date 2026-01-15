# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/server_rendering_js_code"

RSpec.describe ReactOnRailsPro::ServerRenderingJsCode do
  describe ".async_props_setup_js" do
    context "when async_props_block is NOT present in render_options" do
      let(:render_options) do
        instance_double(
          ReactOnRails::ReactComponent::RenderOptions,
          internal_option: nil
        )
      end

      it "returns empty string" do
        result = described_class.async_props_setup_js(render_options)

        expect(result).to eq("")
      end
    end

    context "when async_props_block is present in render_options" do
      let(:async_props_block) { proc { { data: "async_data" } } }
      let(:render_options) do
        instance_double(
          ReactOnRails::ReactComponent::RenderOptions,
          internal_option: async_props_block
        )
      end

      it "returns JavaScript code that sets up AsyncPropsManager" do
        result = described_class.async_props_setup_js(render_options)

        expect(result).to include("ReactOnRails.isRSCBundle")
        expect(result).to include("ReactOnRails.addAsyncPropsCapabilityToComponentProps(usedProps, sharedExecutionContext)")
        expect(result).to include("propsWithAsyncProps")
        expect(result).to include("usedProps = propsWithAsyncProps")
      end
    end
  end

  describe ".render" do
    let(:props_string) { '{"name":"Test"}' }
    let(:rails_context) { '{"serverSide":true}' }
    let(:redux_stores) { "" }
    let(:react_component_name) { "TestComponent" }

    context "when async_props_block is present" do
      let(:async_props_block) { proc { { data: "async_data" } } }
      let(:render_options) do
        instance_double(
          ReactOnRails::ReactComponent::RenderOptions,
          internal_option: async_props_block,
          streaming?: false,
          dom_id: "TestComponent-0",
          trace: false
        )
      end

      before do
        allow(ReactOnRailsPro.configuration).to receive_messages(
          enable_rsc_support: false,
          throw_js_errors: false,
          rendering_returns_promises: false,
          ssr_pre_hook_js: nil
        )
      end

      it "includes async props setup JavaScript in the generated code" do
        result = described_class.render(
          props_string,
          rails_context,
          redux_stores,
          react_component_name,
          render_options
        )

        expect(result).to include("var usedProps = typeof props === 'undefined' ?")
        expect(result).to include("ReactOnRails.isRSCBundle")
        expect(result).to include("ReactOnRails.addAsyncPropsCapabilityToComponentProps(usedProps, sharedExecutionContext)")
      end
    end

    context "when async_props_block is NOT present" do
      let(:render_options) do
        instance_double(
          ReactOnRails::ReactComponent::RenderOptions,
          internal_option: nil,
          streaming?: false,
          dom_id: "TestComponent-0",
          trace: false
        )
      end

      before do
        allow(ReactOnRailsPro.configuration).to receive_messages(
          enable_rsc_support: false,
          throw_js_errors: false,
          rendering_returns_promises: false,
          ssr_pre_hook_js: nil
        )
      end

      it "does NOT include async props setup JavaScript in the generated code" do
        result = described_class.render(
          props_string,
          rails_context,
          redux_stores,
          react_component_name,
          render_options
        )

        expect(result).to include("var usedProps = typeof props === 'undefined' ?")
        expect(result).not_to include("ReactOnRails.addAsyncPropsCapabilityToComponentProps")
        expect(result).not_to include("asyncPropManager")
      end
    end
  end
end
