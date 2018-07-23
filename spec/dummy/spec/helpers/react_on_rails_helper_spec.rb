# frozen_string_literal: true

require "rails_helper"
require "support/script_tag_utils"

describe ReactOnRailsHelper, type: :helper do
  before do
    allow(self).to receive(:request) {
      OpenStruct.new(
        original_url: "http://foobar.com/development",
        env: { "HTTP_ACCEPT_LANGUAGE" => "en" }
      )
    }
  end

  let(:hash) do
    {
      hello: "world",
      free: "of charge",
      x: "</script><script>alert('foo')</script>"
    }
  end

  let(:json_string_sanitized) do
    '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip'\
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
  end

  let(:json_string_unsanitized) do
    "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
  end

  describe "#json_safe_and_pretty(hash_or_string)" do
    it "should raise an error if not hash nor string nor nil passed" do
      expect { helper.json_safe_and_pretty(false) }.to raise_error
    end

    it "should return empty json when an empty Hash" do
      escaped_json = helper.json_safe_and_pretty({})
      expect(escaped_json).to eq("{}")
    end

    it "should return empty json when an empty HashWithIndifferentAccess" do
      escaped_json = helper.json_safe_and_pretty(HashWithIndifferentAccess.new)
      expect(escaped_json).to eq("{}")
    end

    it "should return empty json when nil" do
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
    before { allow(SecureRandom).to receive(:uuid).and_return(0, 1, 2, 3) }

    subject { react_component("App", props: props) }

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

    let(:react_definition_script_random) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" \
        data-component-name="App" data-dom-id="App-react-component-0">{"name":"My Test Name"}</script>
      SCRIPT
    end

    let(:react_definition_script) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" \
        data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
      SCRIPT
    end

    let(:react_definition_script_no_params) do
      <<-SCRIPT.strip_heredoc
        <script type="application/json" class="js-react-on-rails-component" \
        data-component-name="App" data-dom-id="App-react-component">{}</script>
      SCRIPT
    end

    context "with json string props" do
      let(:json_props) do
        "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
      end

      let(:json_props_sanitized) do
        '{"hello":"world","free":"of charge","x":"\\u003c/script\\u003e\\u003cscrip'\
          "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
      end

      subject { react_component("App", props: json_props) }
      it { is_expected.to include json_props_sanitized }
    end

    describe "API with component name only (no props or other options)" do
      subject { react_component("App") }
      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }
      it {
        expect(is_expected.target).to script_tag_be_included(react_definition_script_no_params)
      }
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<script" }
    it { is_expected.to match %r{</script>\s*$} }
    it { is_expected.to include react_component_div }
    it {
      expect(is_expected.target).to script_tag_be_included(react_definition_script)
    }

    context "with 'random_dom_id' false option" do
      subject { react_component("App", props: props, random_dom_id: false) }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(is_expected.target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' false option" do
      subject { react_component("App", props: props, random_dom_id: true) }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" data-component-name="App" data-dom-id="App-react-component-0">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component-0"></div>' }
      it { expect(is_expected.target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'random_dom_id' global" do
      around(:example) do |example|
        ReactOnRails.configure { |config| config.random_dom_id = false }
        example.run
        ReactOnRails.configure { |config| config.random_dom_id = true }
      end

      subject { react_component("App", props: props) }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" data-component-name="App" data-dom-id="App-react-component">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include '<div id="App-react-component"></div>' }
      it { expect(is_expected.target).to script_tag_be_included(react_definition_script) }
    end

    context "with 'id' option" do
      subject { react_component("App", props: props, id: id) }

      let(:id) { "shaka_div" }

      let(:react_definition_script) do
        <<-SCRIPT.strip_heredoc
          <script type="application/json" class="js-react-on-rails-component" data-component-name="App" data-dom-id="shaka_div">{"name":"My Test Name"}</script>
        SCRIPT
      end

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_random_id_div }
      it {
        expect(is_expected.target).to script_tag_be_included(react_definition_script)
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
  end

  describe "#redux_store" do
    subject { redux_store("reduxStore", props: props) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_store_script) do
      '<script type="application/json" data-js-react-on-rails-store="reduxStore">'\
        '{"name":"My Test Name"}'\
      "</script>"
    end

    it { expect(self).to respond_to :redux_store }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<script" }
    it { is_expected.to end_with "</script>" }
    it {
      expect(is_expected.target).to script_tag_be_included(react_store_script)
    }
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
    before do
      @rendering_extension = ReactOnRails.configuration.rendering_extension
      ReactOnRails.configuration.rendering_extension = nil
    end

    after { ReactOnRails.configuration.rendering_extension = @rendering_extension }

    it "should not throw an error if not in a view" do
      class PlainClass
        include ReactOnRailsHelper
      end

      ob = PlainClass.new
      expect { ob.send(:rails_context, server_side: true) }.to_not raise_error
      expect { ob.send(:rails_context, server_side: false) }.to_not raise_error
    end
  end
end
