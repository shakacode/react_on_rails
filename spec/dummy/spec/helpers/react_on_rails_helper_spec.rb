# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

class PlainReactOnRailsHelper
  include ReactOnRailsHelper
  include ActionView::Helpers::TagHelper
end

# rubocop:disable Metrics/BlockLength
describe ReactOnRailsHelper do
  include Shakapacker::Helper

  before do
    allow(self).to receive(:request) {
      Struct.new("Request", :original_url, :env)
      Struct::Request.new(
        "http://foobar.com/development",
        { "HTTP_ACCEPT_LANGUAGE" => "en" }
      )
    }

    allow(ReactOnRails::Utils).to receive_messages(
      react_on_rails_pro?: true,
      react_on_rails_pro_version: "",
      rsc_support_enabled?: false
    )

    # Stub ReactOnRailsPro::Utils.pro_attribution_comment for all tests
    # since react_on_rails_pro? is set to true by default
    pro_module = Module.new
    utils_module = Module.new do
      def self.pro_attribution_comment
        "<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->"
      end
    end
    stub_const("ReactOnRailsPro", pro_module)
    stub_const("ReactOnRailsPro::Utils", utils_module)

    # Stub react_on_rails_pro? to return true for tests since they expect that behavior
    allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
  end

  let(:hash) do
    {
      hello: "world",
      free: "of charge",
      x: "</script><script>alert('foo')</script>"
    }
  end

  let(:json_string_sanitized) do
    '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip' \
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
  end

  let(:json_string_unsanitized) do
    "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
  end

  describe "#load_pack_for_generated_component" do
    let(:render_options) do
      ReactOnRails::ReactComponent::RenderOptions.new(react_component_name: "component_name",
                                                      options: {})
    end

    it "appends js/css pack tag" do
      allow(helper).to receive(:append_javascript_pack_tag)
      allow(helper).to receive(:append_stylesheet_pack_tag)
      expect { helper.load_pack_for_generated_component("component_name", render_options) }.not_to raise_error

      # Default loading strategy is now always :defer to prevent race conditions
      # between component registration and hydration, regardless of async support
      expect(helper).to have_received(:append_javascript_pack_tag).with("generated/component_name", { defer: true })
      expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/component_name")
    end

    context "when async loading is enabled" do
      before do
        allow(ReactOnRails.configuration).to receive(:generated_component_packs_loading_strategy).and_return(:async)
      end

      it "appends the async attribute to the script tag" do
        original_append_javascript_pack_tag = helper.method(:append_javascript_pack_tag)
        begin
          # Temporarily redefine append_javascript_pack_tag to handle the async keyword argument.
          # This is needed because older versions of Shakapacker (which may be used during testing)
          # don't support async loading, but we still want to test that the async option is passed
          # correctly when enabled.
          def helper.append_javascript_pack_tag(name, **options)
            original_append_javascript_pack_tag.call(name, **options)
          end

          allow(helper).to receive(:append_javascript_pack_tag)
          allow(helper).to receive(:append_stylesheet_pack_tag)
          expect { helper.load_pack_for_generated_component("component_name", render_options) }.not_to raise_error
          expect(helper).to have_received(:append_javascript_pack_tag).with(
            "generated/component_name",
            { defer: false, async: true }
          )
          expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/component_name")
        ensure
          helper.define_singleton_method(:append_javascript_pack_tag, original_append_javascript_pack_tag)
        end
      end
    end

    context "when defer loading is enabled" do
      before do
        allow(ReactOnRails.configuration).to receive(:generated_component_packs_loading_strategy).and_return(:defer)
      end

      it "appends the defer attribute to the script tag" do
        allow(helper).to receive(:append_javascript_pack_tag)
        allow(helper).to receive(:append_stylesheet_pack_tag)
        expect { helper.load_pack_for_generated_component("component_name", render_options) }.not_to raise_error
        expect(helper).to have_received(:append_javascript_pack_tag).with("generated/component_name", { defer: true })
        expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/component_name")
      end
    end

    it "throws an error in development if generated component isn't found" do
      allow(Rails.env).to receive(:development?).and_return(true)
      expect { helper.load_pack_for_generated_component("nonexisting_component", render_options) }
        .to raise_error(ReactOnRails::SmartError, /Auto-loaded Bundle Missing/)
    end
  end

  describe "#json_safe_and_pretty(hash_or_string)" do
    it "raises an error if not hash nor string nor nil passed" do
      expect { helper.json_safe_and_pretty(false) }.to raise_error(ReactOnRails::Error)
    end

    it "returns empty json when an empty Hash" do
      escaped_json = helper.json_safe_and_pretty({})
      expect(escaped_json).to eq("{}")
    end

    it "returns empty json when an empty HashWithIndifferentAccess" do
      escaped_json = helper.json_safe_and_pretty(HashWithIndifferentAccess.new)
      expect(escaped_json).to eq("{}")
    end

    it "returns empty json when nil" do
      escaped_json = helper.json_safe_and_pretty(nil)
      expect(escaped_json).to eq("{}")
    end

    it "converts a hash to escaped JSON" do
      escaped_json = helper.json_safe_and_pretty(hash)
      expect(escaped_json).to eq(json_string_sanitized)
    end

    it "converts a string to escaped JSON" do
      escaped_json = helper.json_safe_and_pretty(json_string_unsanitized)
      expect(escaped_json).to eq(json_string_sanitized)
    end

    context "when json is an instance of ActiveSupport::SafeBuffer" do
      it "converts to escaped JSON" do
        json = ActiveSupport::SafeBuffer.new(
          "{\"hello\":\"world\"}"
        )

        result = helper.json_safe_and_pretty(json)

        expect(result).to eq('{"hello":"world"}')
      end
    end
  end

  describe "#sanitized_props_string(props)" do
    it "converts a hash to JSON and escapes </script>" do
      sanitized = helper.sanitized_props_string(hash)
      expect(sanitized).to eq(json_string_sanitized)
    end

    it "leaves a string alone that does not contain xss tags" do
      sanitized = helper.sanitized_props_string(json_string_sanitized)
      expect(sanitized).to eq(json_string_sanitized)
    end

    it "fixes a string alone that contain xss tags" do
      sanitized = helper.sanitized_props_string(json_string_unsanitized)
      expect(sanitized).to eq(json_string_sanitized)
    end
  end

  describe "#react_component" do
    subject(:react_app) { react_component("App", props: props) }

    before { allow(SecureRandom).to receive(:uuid).and_return(0, 1, 2, 3) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_component_random_id_div) do
      '<div id="App-react-component-0"></div>'
    end

    let(:react_component_div) do
      '<div id="App-react-component"></div>'
    end

    let(:id) { "App-react-component-0" }

    let(:react_definition_script) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" \
        id="js-react-on-rails-component-App-react-component" \
        data-component-name="App" data-dom-id="App-react-component"
        data-immediate-hydration="true">{"name":"My Test Name"}</script>
      SCRIPT
    end

    let(:react_definition_script_no_params) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" \
        id="js-react-on-rails-component-App-react-component" \
        data-component-name="App" data-dom-id="App-react-component"
        data-immediate-hydration="true">{}</script>
      SCRIPT
    end

    context "with json string props" do
      subject { react_component("App", props: json_props) }

      let(:json_props) do
        "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
      end

      let(:json_props_sanitized) do
        '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip' \
          "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
      end

      it { is_expected.to include json_props_sanitized }
    end

    describe "API with component name only (no props or other options)" do
      subject(:react_app) { react_component("App") }

      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }

      it {
        expect(expect(react_app).target).to script_tag_be_included(react_definition_script_no_params)
      }
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<!--" }
    it { is_expected.to match %r{</script>\s*$} }
    it { is_expected.to include react_component_div }

    it {
      expect(expect(react_app).target).to script_tag_be_included(react_definition_script)
    }

    context "with 'random_dom_id' option set to false" do
      subject(:react_app) { react_component("App", props: props, random_dom_id: false) }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component" \
          data-component-name="App" data-dom-id="App-react-component"
          data-immediate-hydration="true">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' option set to true" do
      subject(:react_app) { react_component("App", props: props, random_dom_id: true) }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component-0" \
          data-component-name="App" data-dom-id="App-react-component-0"
          data-immediate-hydration="true">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component-0"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' global" do
      subject(:react_app) { react_component("App", props: props) }

      around do |example|
        ReactOnRails.configure { |config| config.random_dom_id = false }
        example.run
        ReactOnRails.configure { |config| config.random_dom_id = true }
      end

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component" \
          data-component-name="App" data-dom-id="App-react-component"
          data-immediate-hydration="true">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'id' option" do
      subject(:react_app) { react_component("App", props: props, id: id) }

      let(:id) { "shaka_div" }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-shaka_div" \
          data-component-name="App" data-dom-id="shaka_div"
          data-immediate-hydration="true">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_random_id_div }

      it {
        expect(expect(react_app).target).to script_tag_be_included(react_definition_script)
      }
    end

    context "with 'trace' == true" do
      it "adds the data-trace tag to the component_specification_tag" do
        result = react_component("App", trace: true)

        expect(result).to match(/data-trace="true"/)
      end
    end

    context "with 'trace' == false" do
      it "does not add the data-trace tag" do
        result = react_component("App", trace: false)

        expect(result).not_to match(/data-trace=/)
      end
    end

    context "with 'html_options' tag option" do
      subject { react_component("App", html_options: { tag: "span" }) }

      it { is_expected.to include '<span id="App-react-component-0"></span>' }
      it { is_expected.not_to include '<div id="App-react-component-0"></div>' }
    end

    context "without 'html_options' tag option" do
      subject { react_component("App") }

      it { is_expected.not_to include '<span id="App-react-component-0"></span>' }
      it { is_expected.to include '<div id="App-react-component-0"></div>' }
    end

    describe "'immediate_hydration' tag option" do
      let(:immediate_hydration_script) do
        %(typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('App-react-component-0');)
          .html_safe
      end

      context "with 'immediate_hydration' == false" do
        subject { react_component("App", immediate_hydration: false) }

        it { is_expected.not_to include immediate_hydration_script }
      end

      context "without 'immediate_hydration' tag option" do
        subject { react_component("App") }

        it { is_expected.to include immediate_hydration_script }
      end
    end
  end

  describe "#react_component_hash" do
    subject(:react_app) { react_component_hash("App", props: props) }

    let(:props) { { name: "My Test Name" } }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(0)
      allow(ReactOnRails::ServerRenderingPool).to receive(:server_render_js_with_console_logging).and_return(
        "html" => { "componentHtml" => "<div>Test</div>", "title" => "Test Title" },
        "consoleReplayScript" => ""
      )
      allow(ReactOnRails::ServerRenderingJsCode).to receive(:js_code_renderer)
        .and_return(ReactOnRails::ServerRenderingJsCode)
    end

    it "returns a hash with component and other keys" do
      expect(react_app).to be_a(Hash)
      expect(react_app).to have_key("componentHtml")
      expect(react_app).to have_key("title")
    end
  end

  describe "#redux_store" do
    subject(:store) { redux_store("reduxStore", props: props, immediate_hydration: true) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_store_script) do
      '<script type="application/json" data-js-react-on-rails-store="reduxStore" data-immediate-hydration="true">' \
        '{"name":"My Test Name"}' \
        "</script>"
    end

    it { expect(self).to respond_to :redux_store }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<!--" }
    it { is_expected.to end_with "</script>" }

    it {
      expect(expect(store).target).to script_tag_be_included(react_store_script)
    }

    context "without Pro license" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      context "with immediate_hydration option set to true (not recommended)" do
        it "returns false for immediate_hydration and logs a warning" do
          expect(Rails.logger).to receive(:warn).with(/immediate_hydration: true requires a React on Rails Pro license/)

          result = redux_store("reduxStore", props: props, immediate_hydration: true)

          # Verify that the store tag does NOT have immediate hydration enabled
          expect(result).not_to include('data-immediate-hydration="true"')
        end
      end

      context "with immediate_hydration option set to false" do
        it "returns false for immediate_hydration without warning" do
          expect(Rails.logger).not_to receive(:warn)

          result = redux_store("reduxStore", props: props, immediate_hydration: false)

          # Verify that the store tag does NOT have immediate hydration enabled
          expect(result).not_to include('data-immediate-hydration="true"')
        end
      end

      context "without immediate_hydration option (nil)" do
        it "defaults to false for non-Pro users" do
          result = redux_store("reduxStore", props: props)

          # Verify that the store tag does NOT have immediate hydration enabled
          expect(result).not_to include('data-immediate-hydration="true"')
        end
      end
    end
  end

  describe "#server_render_js", :js, type: :system do
    subject { server_render_js("ReactOnRails.getComponent('HelloString').component.world()") }

    let(:hello_world) do
      "Hello WORLD! Will this work?? YES! Time to visit Maui"
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to eq hello_world }
  end

  describe "#rails_context" do
    around do |example|
      rendering_extension = ReactOnRails.configuration.rendering_extension
      ReactOnRails.configuration.rendering_extension = nil

      example.run

      ReactOnRails.configuration.rendering_extension = rendering_extension
    end

    it "does not throw an error if not in a view" do
      ob = PlainReactOnRailsHelper.new
      expect { ob.send(:rails_context, server_side: true) }.not_to raise_error
      expect { ob.send(:rails_context, server_side: false) }.not_to raise_error
    end
  end

  describe "#rails_context_if_not_already_rendered" do
    let(:helper) { PlainReactOnRailsHelper.new }

    before do
      allow(helper).to receive(:rails_context).and_return({ some: "context" })
    end

    it "returns a script tag with rails context when not already rendered" do
      result = helper.send(:rails_context_if_not_already_rendered)
      expect(result).to include('<script type="application/json" id="js-react-on-rails-context">')
      expect(result).to include('"some":"context"')
    end

    it "returns an empty string when already rendered" do
      helper.instance_variable_set(:@rendered_rails_context, true)
      result = helper.send(:rails_context_if_not_already_rendered)
      expect(result).to eq("")
    end

    it "calls rails_context with server_side: false" do
      helper.send(:rails_context_if_not_already_rendered)
      expect(helper).to have_received(:rails_context).with(server_side: false)
    end
  end

  describe "#react_on_rails_attribution_comment" do
    let(:helper) { PlainReactOnRailsHelper.new }

    context "when React on Rails Pro is installed" do
      let(:pro_comment) { "<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->" }

      before do
        # ReactOnRailsPro::Utils is already stubbed in global before block
        # Just override the return value for this context
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        allow(ReactOnRailsPro::Utils).to receive(:pro_attribution_comment).and_return(pro_comment)
      end

      it "returns the Pro attribution comment" do
        result = helper.send(:react_on_rails_attribution_comment)
        expect(result).to eq(pro_comment)
      end

      it "calls ReactOnRailsPro::Utils.pro_attribution_comment" do
        helper.send(:react_on_rails_attribution_comment)
        expect(ReactOnRailsPro::Utils).to have_received(:pro_attribution_comment)
      end
    end

    context "when React on Rails Pro is NOT installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "returns the open source attribution comment" do
        result = helper.send(:react_on_rails_attribution_comment)
        expect(result).to eq("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
      end
    end
  end

  describe "attribution comment inclusion in rendered output" do
    let(:props) { { name: "Test" } }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(0)
    end

    describe "#react_component" do
      context "when React on Rails Pro is installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          allow(ReactOnRailsPro::Utils).to receive(:pro_attribution_comment)
            .and_return("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the Pro attribution comment in the rendered output" do
          result = react_component("App", props: props)
          expect(result).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = react_component("App", props: props)
          comment_count = result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the rendered output" do
          result = react_component("App", props: props)
          expect(result).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = react_component("App", props: props)
          comment_count = result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end
      end
    end

    describe "#redux_store" do
      context "when React on Rails Pro is installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          allow(ReactOnRailsPro::Utils).to receive(:pro_attribution_comment)
            .and_return("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the Pro attribution comment in the rendered output" do
          result = redux_store("TestStore", props: props)
          expect(result).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = redux_store("TestStore", props: props)
          comment_count = result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the rendered output" do
          result = redux_store("TestStore", props: props)
          expect(result).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = redux_store("TestStore", props: props)
          comment_count = result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end
      end
    end

    describe "#react_component_hash" do
      before do
        allow(ReactOnRails::ServerRenderingPool).to receive(:server_render_js_with_console_logging).and_return(
          "html" => { "componentHtml" => "<div>Test</div>", "title" => "Test Title" },
          "consoleReplayScript" => ""
        )
        allow(ReactOnRails::ServerRenderingJsCode).to receive(:js_code_renderer)
          .and_return(ReactOnRails::ServerRenderingJsCode)
      end

      context "when React on Rails Pro is installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          allow(ReactOnRailsPro::Utils).to receive(:pro_attribution_comment)
            .and_return("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the Pro attribution comment in the componentHtml" do
          result = react_component_hash("App", props: props, prerender: true)
          expect(result["componentHtml"]).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = react_component_hash("App", props: props, prerender: true)
          comment_count = result["componentHtml"].scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the componentHtml" do
          result = react_component_hash("App", props: props, prerender: true)
          expect(result["componentHtml"]).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = react_component_hash("App", props: props, prerender: true)
          comment_count = result["componentHtml"].scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end
      end
    end

    describe "single attribution comment per page" do
      context "when React on Rails Pro is installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          allow(ReactOnRailsPro::Utils).to receive(:pro_attribution_comment)
            .and_return("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once when calling multiple react_component helpers" do
          result1 = react_component("App1", props: props)
          result2 = react_component("App2", props: props)
          combined_result = result1 + result2

          comment_count = combined_result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling mixed SSR helpers" do
          component_result = react_component("App", props: props)
          store_result = redux_store("TestStore", props: props)
          combined_result = component_result + store_result

          comment_count = combined_result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling react_component multiple times" do
          results = Array.new(5) { |i| react_component("App#{i}", props: props) }
          combined_result = results.join

          comment_count = combined_result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the attribution comment only once when calling multiple react_component helpers" do
          result1 = react_component("App1", props: props)
          result2 = react_component("App2", props: props)
          combined_result = result1 + result2

          comment_count = combined_result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling mixed SSR helpers" do
          component_result = react_component("App", props: props)
          store_result = redux_store("TestStore", props: props)
          combined_result = component_result + store_result

          comment_count = combined_result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end
      end
    end
  end

  describe "#wrap_console_script_with_nonce" do
    let(:helper) { PlainReactOnRailsHelper.new }
    let(:console_script) { "console.log.apply(console, ['[SERVER] test message']);" }

    context "when CSP nonce is available" do
      before do
        def helper.respond_to?(method_name, *args)
          return true if method_name == :content_security_policy_nonce

          super
        end

        def helper.content_security_policy_nonce(_directive = nil)
          "abc123"
        end
      end

      it "wraps script with nonce attribute" do
        result = helper.send(:wrap_console_script_with_nonce, console_script)
        expect(result).to include('nonce="abc123"')
        expect(result).to include('id="consoleReplayLog"')
        expect(result).to include(console_script)
      end

      it "creates a valid script tag" do
        result = helper.send(:wrap_console_script_with_nonce, console_script)
        expect(result).to match(%r{<script.*id="consoleReplayLog".*>.*</script>})
      end
    end

    context "when CSP is not configured" do
      before do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:content_security_policy_nonce).and_return(false)
      end

      it "wraps script without nonce attribute" do
        result = helper.send(:wrap_console_script_with_nonce, console_script)
        expect(result).not_to include("nonce=")
        expect(result).to include('id="consoleReplayLog"')
        expect(result).to include(console_script)
      end
    end

    context "with Rails 5.2-6.0 compatibility (ArgumentError fallback)" do
      before do
        def helper.respond_to?(method_name, *args)
          return true if method_name == :content_security_policy_nonce

          super
        end

        def helper.content_security_policy_nonce(*args)
          raise ArgumentError if args.any?

          "fallback123"
        end
      end

      it "falls back to no-argument method" do
        result = helper.send(:wrap_console_script_with_nonce, console_script)
        expect(result).to include('nonce="fallback123"')
      end
    end

    context "with blank input" do
      it "returns empty string for empty input" do
        expect(helper.send(:wrap_console_script_with_nonce, "")).to eq("")
      end

      it "returns empty string for nil input" do
        expect(helper.send(:wrap_console_script_with_nonce, nil)).to eq("")
      end

      it "returns empty string for whitespace-only input" do
        expect(helper.send(:wrap_console_script_with_nonce, "   ")).to eq("")
      end
    end

    context "with multiple console statements" do
      let(:multi_line_script) do
        <<~JS.strip
          console.log.apply(console, ['[SERVER] line 1']);
          console.log.apply(console, ['[SERVER] line 2']);
          console.error.apply(console, ['[SERVER] error']);
        JS
      end

      before do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:content_security_policy_nonce).and_return(false)
      end

      it "preserves newlines in multi-line script" do
        result = helper.send(:wrap_console_script_with_nonce, multi_line_script)
        expect(result).to include("line 1")
        expect(result).to include("line 2")
        expect(result).to include("error")
        # Verify newlines are preserved (not collapsed)
        expect(result.scan(/console\.(log|error)\.apply/).count).to eq(3)
      end
    end

    context "with special characters in script" do
      let(:script_with_quotes) { %q{console.log.apply(console, ['[SERVER] "quoted" text']);} }

      before do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:content_security_policy_nonce).and_return(false)
      end

      it "properly escapes content in script tag" do
        result = helper.send(:wrap_console_script_with_nonce, script_with_quotes)
        expect(result).to include(script_with_quotes)
        expect(result).to match(%r{<script.*>.*"quoted".*</script>})
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
