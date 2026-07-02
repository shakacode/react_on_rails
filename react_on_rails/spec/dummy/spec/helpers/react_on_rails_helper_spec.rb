# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

class PlainReactOnRailsHelper
  include ReactOnRailsHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper
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
    let(:react_component_name) { "component_name" }
    let(:generated_component_name) { "ComponentName" }
    let(:render_options) do
      ReactOnRails::ReactComponent::RenderOptions.new(react_component_name:,
                                                      options: {})
    end

    it "appends js/css pack tag" do
      allow(helper).to receive(:append_javascript_pack_tag)
      allow(helper).to receive(:append_stylesheet_pack_tag)
      expect { helper.load_pack_for_generated_component(react_component_name, render_options) }.not_to raise_error

      # Default loading strategy is now always :defer to prevent race conditions
      # between component registration and hydration, regardless of async support
      expect(helper).to have_received(:append_javascript_pack_tag).with("generated/#{generated_component_name}",
                                                                        { defer: true })
      expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/#{generated_component_name}")
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
          expect { helper.load_pack_for_generated_component(react_component_name, render_options) }.not_to raise_error
          expect(helper).to have_received(:append_javascript_pack_tag).with(
            "generated/#{generated_component_name}",
            { defer: false, async: true }
          )
          expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/#{generated_component_name}")
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
        expect { helper.load_pack_for_generated_component(react_component_name, render_options) }.not_to raise_error
        expect(helper).to have_received(:append_javascript_pack_tag).with("generated/#{generated_component_name}",
                                                                          { defer: true })
        expect(helper).to have_received(:append_stylesheet_pack_tag).with("generated/#{generated_component_name}")
      end
    end

    it "throws an error in development if generated component isn't found" do
      missing_render_options = ReactOnRails::ReactComponent::RenderOptions.new(
        react_component_name: "nonexisting_component",
        options: {}
      )
      allow(Rails.env).to receive(:development?).and_return(true)
      expect { helper.load_pack_for_generated_component("nonexisting_component", missing_render_options) }
        .to raise_error(ReactOnRails::SmartError, /Auto-loaded Bundle Missing/)
    end
  end

  describe "#react_on_rails_preload_links" do
    let(:manifest) { instance_double(Shakapacker::Manifest) }
    let(:integrity_config) { { enabled: false, cross_origin: "anonymous" } }
    let(:shakapacker_config) do
      instance_double(Shakapacker::Configuration, integrity: integrity_config, nested_entries?: true)
    end
    let(:shakapacker_instance) { instance_double(Shakapacker::Instance, manifest:, config: shakapacker_config) }

    before do
      allow(Shakapacker).to receive(:instance).and_return(shakapacker_instance)
      allow(manifest).to receive(:lookup_pack_with_chunks!)
      allow(manifest).to receive(:lookup_pack_with_chunks)
    end

    def preload_link_nodes(html)
      Nokogiri::HTML.fragment(html).css("link")
    end

    it "emits script and stylesheet preload tags for a generated component pack" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/HelloWorld", type: :javascript)
        .and_return(["/packs/runtime-123.js", "/packs/generated/HelloWorld-456.js"])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/HelloWorld", type: :stylesheet)
        .and_return(["/packs/generated/HelloWorld-789.css"])

      links = preload_link_nodes(helper.react_on_rails_preload_links("hello_world"))

      expect(links.map { |link| link["href"] }).to eq(
        ["/packs/runtime-123.js", "/packs/generated/HelloWorld-456.js", "/packs/generated/HelloWorld-789.css"]
      )
      expect(links.map { |link| [link["rel"], link["as"]] }).to eq(
        [%w[preload script], %w[preload script], %w[preload style]]
      )
    end

    it "raises the standard nested entries error when generated packs cannot be looked up" do
      allow(ReactOnRails::PackerUtils).to receive(:nested_entries?).and_return(false)

      expect { helper.react_on_rails_preload_links("hello_world") }
        .to raise_error(ReactOnRails::Error, /nested_entries/)
      expect(manifest).not_to have_received(:lookup_pack_with_chunks!)
    end

    it "emits modulepreload tags for module manifest assets" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ModernComponent", type: :javascript)
        .and_return([
                      {
                        "src" => "/packs/generated/ModernComponent-123.js",
                        "type" => "module",
                        "integrity" => "sha384-modern"
                      }
                    ])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ModernComponent", type: :stylesheet)
        .and_return(nil)
      allow(shakapacker_config).to receive(:integrity).and_return({ enabled: true, cross_origin: "anonymous" })

      links = preload_link_nodes(helper.react_on_rails_preload_links("modern_component"))

      expect(links.size).to eq(1)
      expect(links.first["href"]).to eq("/packs/generated/ModernComponent-123.js")
      expect(links.first["rel"]).to eq("modulepreload")
      expect(links.first["as"]).to be_nil
      expect(links.first["integrity"]).to eq("sha384-modern")
      expect(links.first["crossorigin"]).to eq("anonymous")
    end

    it "emits modulepreload tags for mjs assets with query strings" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ModernComponent", type: :javascript)
        .and_return([{ "src" => "/packs/generated/ModernComponent-123.mjs?v=abc" }])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ModernComponent", type: :stylesheet)
        .and_return(nil)

      links = preload_link_nodes(helper.react_on_rails_preload_links("modern_component"))

      expect(links.first["href"]).to eq("/packs/generated/ModernComponent-123.mjs?v=abc")
      expect(links.first["rel"]).to eq("modulepreload")
      expect(links.first["crossorigin"]).to eq("anonymous")
    end

    it "preserves configured crossorigin values on modulepreload tags without integrity" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ModernComponent", type: :javascript)
        .and_return([{ "src" => "/packs/generated/ModernComponent-123.mjs" }])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ModernComponent", type: :stylesheet)
        .and_return(nil)
      allow(shakapacker_config).to receive(:integrity).and_return({ enabled: false, cross_origin: "" })

      links = preload_link_nodes(helper.react_on_rails_preload_links("modern_component"))

      expect(links.first["crossorigin"]).to eq("")
    end

    it "preserves explicit false manifest values when classifying module assets" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/LegacyModule", type: :javascript)
        .and_return([
                      {
                        "src" => "/packs/generated/LegacyModule-123.mjs",
                        # String keys take precedence, so "module" => false wins over module: true.
                        "module" => false,
                        module: true
                      }
                    ])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/LegacyModule", type: :stylesheet)
        .and_return(nil)

      links = preload_link_nodes(helper.react_on_rails_preload_links("legacy_module"))

      expect(links.first["rel"]).to eq("preload")
      expect(links.first["as"]).to eq("script")
    end

    it "preserves configured crossorigin values on modulepreload tags with integrity" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ModernComponent", type: :javascript)
        .and_return([
                      {
                        "src" => "/packs/generated/ModernComponent-123.mjs",
                        "integrity" => "sha384-modern"
                      }
                    ])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ModernComponent", type: :stylesheet)
        .and_return(nil)
      allow(shakapacker_config).to receive(:integrity).and_return({ enabled: true, cross_origin: "" })

      links = preload_link_nodes(helper.react_on_rails_preload_links("modern_component"))

      expect(links.first["crossorigin"]).to eq("")
    end

    it "defaults missing crossorigin values on modulepreload tags with integrity" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ModernComponent", type: :javascript)
        .and_return([
                      {
                        "src" => "/packs/generated/ModernComponent-123.mjs",
                        "integrity" => "sha384-modern"
                      }
                    ])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ModernComponent", type: :stylesheet)
        .and_return(nil)
      allow(shakapacker_config).to receive(:integrity).and_return({ enabled: true })

      links = preload_link_nodes(helper.react_on_rails_preload_links("modern_component"))

      expect(links.first["integrity"]).to eq("sha384-modern")
      expect(links.first["crossorigin"]).to eq("anonymous")
    end

    it "resolves manifest sources through Rails asset paths" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/HostedComponent", type: :javascript)
        .and_return(["/packs/generated/HostedComponent-123.js"])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/HostedComponent", type: :stylesheet)
        .and_return(["/packs/generated/HostedComponent-456.css"])
      allow(helper).to receive(:path_to_asset) do |source, options|
        expect(options).to eq(skip_pipeline: true)
        "https://cdn.example.com#{source}"
      end

      links = preload_link_nodes(helper.react_on_rails_preload_links("hosted_component"))

      expect(links.map { |link| link["href"] }).to eq(
        [
          "https://cdn.example.com/packs/generated/HostedComponent-123.js",
          "https://cdn.example.com/packs/generated/HostedComponent-456.css"
        ]
      )
    end

    it "normalizes prefixed generated pack names consistently" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/HelloWorld", type: :javascript)
        .and_return(["/packs/generated/HelloWorld-456.js"])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/HelloWorld", type: :stylesheet)
        .and_return(nil)

      links = preload_link_nodes(helper.react_on_rails_preload_links("generated/hello_world"))

      expect(links.first["href"]).to eq("/packs/generated/HelloWorld-456.js")
    end

    it "rejects hyphenated component names before manifest lookup" do
      expect { helper.react_on_rails_preload_links("my-component") }
        .to raise_error(ArgumentError, /without hyphens/)
      expect(manifest).not_to have_received(:lookup_pack_with_chunks!)
    end

    it "raises a clear error for hash manifest sources without src" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/BrokenComponent", type: :javascript)
        .and_return([{ "integrity" => "sha384-broken" }])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/BrokenComponent", type: :stylesheet)
        .and_return(nil)

      expect { helper.react_on_rails_preload_links("broken_component") }
        .to raise_error(ArgumentError, /manifest source without src/)
    end

    it "deduplicates shared chunks across component packs" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/HelloWorld", type: :javascript)
        .and_return(["/packs/runtime-123.js", "/packs/generated/HelloWorld-456.js"])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/HelloWorld", type: :stylesheet)
        .and_return(["/packs/shared-789.css"])
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/ReduxApp", type: :javascript)
        .and_return(["/packs/runtime-123.js", "/packs/generated/ReduxApp-456.js"])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/ReduxApp", type: :stylesheet)
        .and_return(["/packs/shared-789.css"])

      links = preload_link_nodes(helper.react_on_rails_preload_links("hello_world", "generated/ReduxApp"))

      expect(links.map { |link| link["href"] }).to eq(
        [
          "/packs/runtime-123.js",
          "/packs/generated/HelloWorld-456.js",
          "/packs/shared-789.css",
          "/packs/generated/ReduxApp-456.js"
        ]
      )
    end

    it "deduplicates assets by href before rendering link attributes" do
      allow(manifest).to receive(:lookup_pack_with_chunks!)
        .with("generated/HelloWorld", type: :javascript)
        .and_return([
                      {
                        "src" => "/packs/runtime-123.js",
                        "integrity" => "sha384-runtime"
                      },
                      "/packs/runtime-123.js"
                    ])
      allow(manifest).to receive(:lookup_pack_with_chunks)
        .with("generated/HelloWorld", type: :stylesheet)
        .and_return(nil)
      allow(shakapacker_config).to receive(:integrity).and_return({ enabled: true, cross_origin: "anonymous" })

      links = preload_link_nodes(helper.react_on_rails_preload_links("hello_world"))

      expect(links.size).to eq(1)
      expect(links.first["href"]).to eq("/packs/runtime-123.js")
      expect(links.first["integrity"]).to eq("sha384-runtime")
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
    subject(:react_app) { react_component("App", props:) }

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
      <<~SCRIPT
        <script type="application/json" class="js-react-on-rails-component" \
        id="js-react-on-rails-component-App-react-component" \
        data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
      SCRIPT
    end

    let(:react_definition_script_no_params) do
      <<~SCRIPT
        <script type="application/json" class="js-react-on-rails-component" \
        id="js-react-on-rails-component-App-react-component" \
        data-component-name="App" data-dom-id="App-react-component">{}</script>
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

    context "when server rendering returns clientProps" do
      before do
        allow(ReactOnRails::ServerRenderingPool).to receive(:server_render_js_with_console_logging).and_return(
          "html" => "<div>SSR App</div>",
          "consoleReplayScript" => "",
          "clientProps" => {
            "__tanstackRouterDehydratedState" => { "url" => "/products?category=tools" }
          }
        )
        allow(ReactOnRails::ServerRenderingJsCode).to receive(:js_code_renderer)
          .and_return(ReactOnRails::ServerRenderingJsCode)
      end

      it "merges clientProps into the component props JSON for client hydration" do
        result = react_component("App", props:, prerender: true)

        expect(result).to include('"name":"My Test Name"')
        expect(result).to include('"__tanstackRouterDehydratedState":{"url":"/products?category=tools"}')
        expect(result).to include('<div id="App-react-component"><div>SSR App</div></div>')
      end

      it "merges clientProps when original props are provided as a JSON string" do
        result = react_component("App", props: '{"name":"My Test Name"}', prerender: true)

        expect(result).to include('"name":"My Test Name"')
        expect(result).to include('"__tanstackRouterDehydratedState":{"url":"/products?category=tools"}')
      end

      it "treats nil props as an empty hash when merging clientProps" do
        result = react_component("App", prerender: true)

        expect(result).to include('"__tanstackRouterDehydratedState":{"url":"/products?category=tools"}')
      end

      it "raises a clear error when JSON string props parse to a non-Hash value" do
        expect do
          react_component("App", props: '["not","a","hash"]', prerender: true)
        end.to raise_error(ReactOnRails::Error, /Cannot merge result\["clientProps"\] into non-Hash props/)
      end

      it "normalizes symbol and string keys so clientProps can override existing props" do
        allow(ReactOnRails::ServerRenderingPool).to receive(:server_render_js_with_console_logging).and_return(
          "html" => "<div>SSR App</div>",
          "consoleReplayScript" => "",
          "clientProps" => {
            "name" => "Name from clientProps"
          }
        )

        result = react_component("App", props: { name: "My Test Name" }, prerender: true)
        expect(result).to include('"name":"Name from clientProps"')
        expect(result.scan('"name":').length).to eq(1)
      end

      it "raises a clear error when merge_client_props sees both string and symbol versions of a key" do
        expect do
          helper.send(
            :merge_client_props,
            { name: "symbol value", "name" => "string value" },
            { "name" => "value from clientProps" }
          )
        end.to raise_error(ReactOnRails::Error, /both string and symbol versions of "name"/)
      end
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

    it "warns when immediate_hydration option is passed" do
      allow(Rails.logger).to receive(:warn)
      ReactOnRails::Helper.reset_removed_immediate_hydration_warnings!

      react_component("App", props:, immediate_hydration: false)
      react_component("App", props:, immediate_hydration: false)

      expect(Rails.logger).to have_received(:warn).once.with(include("immediate_hydration"))
    end

    context "with 'random_dom_id' option set to false" do
      subject(:react_app) { react_component("App", props:, random_dom_id: false) }

      let(:react_definition_script) do
        <<~SCRIPT
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component" \
          data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' option set to true" do
      subject(:react_app) { react_component("App", props:, random_dom_id: true) }

      let(:react_definition_script) do
        <<~SCRIPT
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component-0" \
          data-component-name="App" data-dom-id="App-react-component-0">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component-0"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' global" do
      subject(:react_app) { react_component("App", props:) }

      around do |example|
        ReactOnRails.configure { |config| config.random_dom_id = false }
        example.run
        ReactOnRails.configure { |config| config.random_dom_id = true }
      end

      let(:react_definition_script) do
        <<~SCRIPT
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-App-react-component" \
          data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(expect(react_app).target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'id' option" do
      subject(:react_app) { react_component("App", props:, id:) }

      let(:id) { "shaka_div" }

      let(:react_definition_script) do
        <<~SCRIPT
          <script type="application/json" class="js-react-on-rails-component" \
          id="js-react-on-rails-component-shaka_div" \
          data-component-name="App" data-dom-id="shaka_div">{"name":"My Test Name"}</script>
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

    context "with hydrate_on" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "does not add data-hydrate-on when the option is omitted" do
        result = react_component("App")

        expect(result).not_to match(/data-hydrate-on=/)
      end

      it "does not add data-hydrate-on when hydrate_on is nil" do
        result = react_component("App", hydrate_on: nil)

        expect(result).not_to match(/data-hydrate-on=/)
      end

      it "adds data-hydrate-on for explicit immediate mode" do
        result = react_component("App", hydrate_on: :immediate)

        expect(result).to match(/data-hydrate-on="immediate"/)
      end

      it "adds data-hydrate-on for visible mode" do
        result = react_component("App", hydrate_on: :visible)

        expect(result).to match(/data-hydrate-on="visible"/)
      end

      it "rejects interaction mode because it is not implemented in OSS" do
        expect do
          react_component("App", hydrate_on: :interaction)
        end.to raise_error(ArgumentError, /Supported OSS modes are :immediate, :visible, and :idle/)
      end
    end

    context "with hydrate_on and React on Rails Pro installed" do
      it "rejects deferred scheduling modes" do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        expect do
          react_component("App", hydrate_on: :visible)
        end.to raise_error(ArgumentError, /React on Rails Pro does not support hydrate_on scheduling/)
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

    describe "Pro inline hydration script" do
      let(:hydration_script) do
        %(typeof ReactOnRails === 'object' && ReactOnRails.reactOnRailsComponentLoaded('App-react-component-0');)
          .html_safe
      end

      context "with Pro gem installed" do
        subject { react_component("App") }

        it { is_expected.to include hydration_script }
      end

      context "without Pro gem installed" do
        subject { react_component("App") }

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it { is_expected.not_to include hydration_script }
      end
    end
  end

  describe "#react_component_hash" do
    subject(:react_app) { react_component_hash("App", props:) }

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

    it "warns when immediate_hydration option is passed" do
      allow(Rails.logger).to receive(:warn)
      ReactOnRails::Helper.reset_removed_immediate_hydration_warnings!

      react_component_hash("App", props:, immediate_hydration: false)
      react_component_hash("App", props:, immediate_hydration: false)

      expect(Rails.logger).to have_received(:warn).once.with(include("immediate_hydration"))
    end
  end

  describe "#server_render_js error serialization" do
    let(:runtime_available) do
      ExecJS.runtime&.available?
    rescue ExecJS::RuntimeUnavailable
      false
    end

    let(:runtime_context) do
      ExecJS.compile(<<~JS)
        function runGeneratedCode(generatedCode) {
          var ReactOnRails = {
            handleError: function() { return ''; },
            getConsoleReplayScript: function() { return ''; },
            prepareRenderResult: function(html, consoleReplayScript, hasErrors, renderingError) {
              return JSON.stringify({
                html: html,
                consoleReplayScript: consoleReplayScript,
                hasErrors: hasErrors,
                renderingError: renderingError || null
              });
            }
          };
          // Evaluate generated wrapper JS in a test sandbox before Ruby post-processing.
          return eval(generatedCode);
        }
      JS
    end

    before do
      skip "ExecJS runtime not available" unless runtime_available
    end

    it "generates JS with safe error property access for non-Error throws" do
      captured_results = []

      allow(ReactOnRails::ServerRenderingPool)
        .to receive(:server_render_js_with_console_logging) do |js_code, _opts|
          # Validate generated JS behavior directly before Ruby-side post-processing.
          runtime_result = runtime_context.call("runGeneratedCode", js_code)
          captured_results << JSON.parse(runtime_result)
          {
            "html" => "",
            "consoleReplayScript" => "",
            "hasErrors" => true,
            "renderingError" => { "message" => "stub", "stack" => nil }
          }
        end

      throw_cases = [
        { expression: "(function() { throw null; })()", message: "null", stack: nil },
        { expression: "(function() { throw { code: 42 }; })()", message: "[object Object]", stack: nil },
        { expression: "(function() { throw new Error(\"boom\"); })()", message: "boom", stack: :present }
      ]

      throw_cases.each do |throw_case|
        expect { server_render_js(throw_case[:expression]) }.not_to raise_error
        captured_result = captured_results.last
        expect(captured_result).to be_a(Hash)
        expect(captured_result["hasErrors"]).to be(true)
        expect(captured_result.dig("renderingError", "message")).to eq(throw_case[:message])

        if throw_case[:stack] == :present
          expect(captured_result.dig("renderingError", "stack")).to include("Error: boom")
        else
          expect(captured_result.dig("renderingError", "stack")).to be_nil
        end
      end

      expect(captured_results.length).to eq(throw_cases.length)
    end

    it "raises PrerenderError when throw_js_errors is true and JS throws a non-Error value" do
      allow(ReactOnRails::ServerRenderingPool)
        .to receive(:server_render_js_with_console_logging) do |js_code, _opts|
          runtime_context.call("runGeneratedCode", js_code)
        end

      expect do
        server_render_js("(function() { throw 42; })()", throw_js_errors: true)
      end.to raise_error(ReactOnRails::PrerenderError)
    end

    it "includes streaming renderingError metadata in PrerenderError details" do
      allow(ReactOnRails::Utils).to receive(:full_text_errors_enabled?).and_return(true)

      chunk_result = {
        "consoleReplayScript" => "",
        "hasErrors" => true,
        "renderingError" => {
          "message" => "useState is not a function",
          "stack" => <<~STACK.chomp
            TypeError: useState is not a function
                at CommentsToggle (/app/components/CommentsToggle.jsx:12:15)
          STACK
        }
      }

      expect do
        helper.send(:raise_prerender_error, chunk_result, "CommentsToggle", {}, "generated js")
      end.to raise_error(ReactOnRails::PrerenderError) { |error|
        expect(error.message).to include("useState is not a function")
        expect(error.message).to include("/app/components/CommentsToggle.jsx:12:15")
      }
    end

    it "drops the V8 error-type header line from the backtrace built from renderingError" do
      json_result = {
        "renderingError" => {
          "message" => "useState is not a function",
          "stack" => <<~STACK.chomp
            TypeError: useState is not a function
                at CommentsToggle (/app/components/CommentsToggle.jsx:12:15)
                at PostsPage (/app/components/PostsPage.jsx:8:3)
          STACK
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error.backtrace.first).to start_with("at CommentsToggle")
      expect(error.backtrace).not_to include(/^TypeError:/)
    end

    it "filters non-`at` header lines that appear mid-stack (chained exceptions)" do
      json_result = {
        "renderingError" => {
          "message" => "boom",
          "stack" => <<~STACK.chomp
            TypeError: boom
                at A (/app/a.js:1:1)
            Caused by: Error: root
                at B (/app/b.js:2:2)
          STACK
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error.backtrace).to eq(["at A (/app/a.js:1:1)", "at B (/app/b.js:2:2)"])
    end

    it "builds a diagnostic from a stack-only renderingError with no message" do
      json_result = {
        "renderingError" => {
          "stack" => "TypeError: boom\n    at Foo (/app/foo.js:1:1)"
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error).not_to be_nil
      expect(error.message).to eq("RSC stream metadata reported a rendering error")
      expect(error.backtrace.first).to start_with("at Foo")
    end

    it "returns nil when renderingError has neither message nor stack" do
      error = helper.send(:rendering_error_from_result, { "renderingError" => {} })

      expect(error).to be_nil
    end

    it "ignores a non-String stack (e.g. an array of frames) instead of producing garbage frames" do
      json_result = {
        "renderingError" => {
          "message" => "boom",
          "stack" => ["at A (/app/a.js:1:1)"]
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error.backtrace).to be_nil
    end

    it "leaves backtrace nil when renderingError has no stack so error reporters can enrich it" do
      json_result = {
        "renderingError" => {
          "message" => "useState is not a function"
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error.backtrace).to be_nil
    end

    it "leaves backtrace nil when the stack is a header line with no parseable frames" do
      json_result = {
        "renderingError" => {
          "message" => "useState is not a function",
          "stack" => "TypeError: useState is not a function"
        }
      }

      error = helper.send(:rendering_error_from_result, json_result)

      expect(error.backtrace).to be_nil
    end

    it "raises PrerenderError without crashing when renderingError has no stack (full text errors)" do
      allow(ReactOnRails::Utils).to receive(:full_text_errors_enabled?).and_return(true)

      chunk_result = {
        "consoleReplayScript" => "",
        "hasErrors" => true,
        "renderingError" => { "message" => "useState is not a function" }
      }

      expect do
        helper.send(:raise_prerender_error, chunk_result, "CommentsToggle", {}, "generated js")
      end.to raise_error(ReactOnRails::PrerenderError) { |error|
        expect(error.message).to include("useState is not a function")
      }
    end

    it "raises PrerenderError without crashing when renderingError has no stack (cleaned backtrace)" do
      allow(ReactOnRails::Utils).to receive(:full_text_errors_enabled?).and_return(false)

      chunk_result = {
        "consoleReplayScript" => "",
        "hasErrors" => true,
        "renderingError" => { "message" => "useState is not a function" }
      }

      expect do
        helper.send(:raise_prerender_error, chunk_result, "CommentsToggle", {}, "generated js")
      end.to raise_error(ReactOnRails::PrerenderError) { |error|
        expect(error.message).to include("useState is not a function")
      }
    end
  end

  describe "#redux_store" do
    subject(:store) { redux_store("reduxStore", props:) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_store_script) do
      '<script type="application/json" data-js-react-on-rails-store="reduxStore">' \
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

    it "warns once when immediate_hydration option is passed" do
      allow(Rails.logger).to receive(:warn)
      ReactOnRails::Helper.reset_removed_immediate_hydration_warnings!

      redux_store("reduxStore", props:, immediate_hydration: false)
      redux_store("reduxStore", props:, immediate_hydration: true)

      expect(Rails.logger).to have_received(:warn).once.with(include("immediate_hydration"))
    end

    it "raises an ArgumentError for unknown keywords" do
      expect do
        redux_store("reduxStore", props:, typo_option: true)
      end.to raise_error(ArgumentError, "unknown keyword: :typo_option")
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

    it "adds cspNonce when a nonce is available" do
      helper = PlainReactOnRailsHelper.new
      allow(helper).to receive(:csp_nonce).and_return("nonce123")

      context = helper.send(:rails_context, server_side: true)

      expect(context[:cspNonce]).to eq("nonce123")
    end

    it "omits cspNonce when nonce is not available" do
      helper = PlainReactOnRailsHelper.new
      allow(helper).to receive(:csp_nonce).and_return(nil)

      context = helper.send(:rails_context, server_side: true)

      expect(context).not_to have_key(:cspNonce)
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
          result = react_component("App", props:)
          expect(result).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = react_component("App", props:)
          comment_count = result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the rendered output" do
          result = react_component("App", props:)
          expect(result).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = react_component("App", props:)
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
          result = redux_store("TestStore", props:)
          expect(result).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = redux_store("TestStore", props:)
          comment_count = result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the rendered output" do
          result = redux_store("TestStore", props:)
          expect(result).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = redux_store("TestStore", props:)
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
          result = react_component_hash("App", props:, prerender: true)
          expect(result["componentHtml"]).to include("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end

        it "includes the attribution comment only once" do
          result = react_component_hash("App", props:, prerender: true)
          comment_count = result["componentHtml"].scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end
      end

      context "when React on Rails Pro is NOT installed" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "includes the open source attribution comment in the componentHtml" do
          result = react_component_hash("App", props:, prerender: true)
          expect(result["componentHtml"]).to include("<!-- Powered by React on Rails (c) ShakaCode | Open Source -->")
        end

        it "includes the attribution comment only once" do
          result = react_component_hash("App", props:, prerender: true)
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
          result1 = react_component("App1", props:)
          result2 = react_component("App2", props:)
          combined_result = result1 + result2

          comment_count = combined_result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling mixed SSR helpers" do
          component_result = react_component("App", props:)
          store_result = redux_store("TestStore", props:)
          combined_result = component_result + store_result

          comment_count = combined_result.scan("<!-- Powered by React on Rails Pro").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling react_component multiple times" do
          results = Array.new(5) { |i| react_component("App#{i}", props:) }
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
          result1 = react_component("App1", props:)
          result2 = react_component("App2", props:)
          combined_result = result1 + result2

          comment_count = combined_result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end

        it "includes the attribution comment only once when calling mixed SSR helpers" do
          component_result = react_component("App", props:)
          store_result = redux_store("TestStore", props:)
          combined_result = component_result + store_result

          comment_count = combined_result.scan("<!-- Powered by React on Rails").length
          expect(comment_count).to eq(1)
        end
      end
    end
  end

  describe "#csp_nonce" do
    let(:helper) { PlainReactOnRailsHelper.new }

    context "when CSP nonce is available" do
      before do
        # content_security_policy_nonce is a Rails method not present on PlainReactOnRailsHelper,
        # so we define it on the singleton to simulate a Rails view context with CSP enabled.
        def helper.respond_to?(method_name, *args)
          return true if method_name == :content_security_policy_nonce

          super
        end

        def helper.content_security_policy_nonce(_directive = nil)
          "test-nonce-123"
        end
      end

      it "returns the nonce value" do
        expect(helper.send(:csp_nonce)).to eq("test-nonce-123")
      end
    end

    context "when CSP is not configured" do
      before do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:content_security_policy_nonce).and_return(false)
      end

      it "returns nil" do
        expect(helper.send(:csp_nonce)).to be_nil
      end
    end

    context "with Rails 5.2-6.0 compatibility (ArgumentError fallback)" do
      before do
        # Simulate an older Rails where content_security_policy_nonce raises ArgumentError
        # when called with arguments.
        def helper.respond_to?(method_name, *args)
          return true if method_name == :content_security_policy_nonce

          super
        end

        def helper.content_security_policy_nonce(*args)
          raise ArgumentError if args.any?

          "fallback-nonce"
        end
      end

      it "falls back to no-argument method" do
        expect(helper.send(:csp_nonce)).to eq("fallback-nonce")
      end
    end
  end

  describe "#generate_component_script" do
    let(:helper) { PlainReactOnRailsHelper.new }

    let(:render_options) do
      instance_double(
        ReactOnRails::ReactComponent::RenderOptions,
        client_props: { name: "World" },
        dom_id: "HelloWorld-react-component-0",
        react_component_name: "HelloWorld",
        trace: false,
        hydrate_on: :immediate,
        internal_option: nil,
        store_dependencies: nil,
        html_streaming?: false,
        auto_load_bundle: false
      )
    end

    context "when CSP nonce is available" do
      before do
        allow(helper).to receive(:csp_nonce).and_return("component-nonce-abc")
      end

      it "adds nonce to the Pro hydration script" do
        result = helper.send(:generate_component_script, render_options)
        expect(result).to include('nonce="component-nonce-abc"')
        expect(result).to include("reactOnRailsComponentLoaded")
      end

      it "does not add nonce to the application/json script" do
        result = helper.send(:generate_component_script, render_options)
        json_tag_match = result.match(%r{<script type="application/json"[^>]*>})
        expect(json_tag_match.to_s).not_to include("nonce=")
      end
    end

    context "when CSP is not configured" do
      before do
        allow(helper).to receive(:csp_nonce).and_return(nil)
      end

      it "does not add nonce to the Pro hydration script" do
        result = helper.send(:generate_component_script, render_options)
        expect(result).not_to include("nonce=")
        expect(result).to include("reactOnRailsComponentLoaded")
      end
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "does not include a hydration script" do
        result = helper.send(:generate_component_script, render_options)
        expect(result).not_to include("reactOnRailsComponentLoaded")
      end
    end

    context "when auto-loaded generated stylesheet hrefs are available" do
      let(:stylesheet_sources) do
        [{ source: "css/shared-generated-pack-deadbeef.css", source_type: :stylesheet }]
      end

      before do
        allow(render_options).to receive(:auto_load_bundle).and_return(true)
        allow(helper).to receive(:preload_sources_for_stylesheet_pack)
          .with("generated/HelloWorld")
          .and_return(stylesheet_sources)
        allow(helper).to receive(:unique_preload_sources_by_href)
          .with(stylesheet_sources)
          .and_return([{ href: "/webpack/test/css/shared-generated-pack-deadbeef.css" }])
      end

      it "adds generated stylesheet href metadata to the component specification script" do
        result = helper.send(:generate_component_script, render_options)
        script = Nokogiri::HTML.fragment(result).css("script.js-react-on-rails-component").first

        expect(script["data-generated-stylesheet-hrefs"])
          .to eq(["/webpack/test/css/shared-generated-pack-deadbeef.css"].to_json)
      end
    end
  end

  describe "#generate_store_script" do
    let(:helper) { PlainReactOnRailsHelper.new }

    let(:redux_store_data) do
      {
        props: { count: 0 },
        store_name: "MyStore"
      }
    end

    context "when CSP nonce is available" do
      before do
        allow(helper).to receive(:csp_nonce).and_return("store-nonce-xyz")
      end

      it "adds nonce to the Pro hydration script" do
        result = helper.send(:generate_store_script, redux_store_data)
        expect(result).to include('nonce="store-nonce-xyz"')
        expect(result).to include("reactOnRailsStoreLoaded")
      end

      it "does not add nonce to the application/json script" do
        result = helper.send(:generate_store_script, redux_store_data)
        json_tag_match = result.match(%r{<script type="application/json"[^>]*>})
        expect(json_tag_match.to_s).not_to include("nonce=")
      end
    end

    context "when CSP is not configured" do
      before do
        allow(helper).to receive(:csp_nonce).and_return(nil)
      end

      it "does not add nonce to the Pro hydration script" do
        result = helper.send(:generate_store_script, redux_store_data)
        expect(result).not_to include("nonce=")
        expect(result).to include("reactOnRailsStoreLoaded")
      end
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "does not include a hydration script" do
        result = helper.send(:generate_store_script, redux_store_data)
        expect(result).not_to include("reactOnRailsStoreLoaded")
      end
    end

    it "escapes store_name when serializing data-js-react-on-rails-store" do
      injected_store_name = 'MyStore" onmouseover="alert(1)'
      result = helper.send(
        :generate_store_script,
        {
          props: { count: 0 },
          store_name: injected_store_name
        }
      )

      expect(result).to include(
        'data-js-react-on-rails-store="MyStore&quot; onmouseover=&quot;alert(1)"'
      )
      expect(result).not_to include('data-js-react-on-rails-store="MyStore" onmouseover=')
    end
  end

  describe "#wrap_console_script_with_nonce" do
    let(:helper) { PlainReactOnRailsHelper.new }
    let(:console_script) { "console.log.apply(console, ['[SERVER] test message']);" }

    context "when CSP nonce is available" do
      before do
        allow(helper).to receive(:csp_nonce).and_return("abc123")
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
        allow(helper).to receive(:csp_nonce).and_return(nil)
      end

      it "wraps script without nonce attribute" do
        result = helper.send(:wrap_console_script_with_nonce, console_script)
        expect(result).not_to include("nonce=")
        expect(result).to include('id="consoleReplayLog"')
        expect(result).to include(console_script)
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
        allow(helper).to receive(:csp_nonce).and_return(nil)
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
        allow(helper).to receive(:csp_nonce).and_return(nil)
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
