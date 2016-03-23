require "rails_helper"

describe ReactOnRailsHelper, type: :helper do
  before do
    allow(self).to receive(:request) {
      OpenStruct.new(
        original_url: "http://foobar.com/development",
        env: { "HTTP_ACCEPT_LANGUAGE" => "en" }
      )
    }
  end

  describe "#sanitized_props_string(props)" do
    let(:hash) do
      {
        hello: "world",
        free: "of charge",
        x: "</script><script>alert('foo')</script>"
      }
    end

    let(:hash_sanitized) do
      "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"\\u003c/script\\u003e\\u003cscrip"\
      "t\\u003ealert('foo')\\u003c/script\\u003e\"}"
    end

    let(:hash_unsanitized) do
      "{\"hello\":\"world\",\"free\":\"of charge\",\"x\":\"</script><script>alert('foo')</script>\"}"
    end

    it "converts a hash to JSON and escapes </script>" do
      sanitized = helper.sanitized_props_string(hash)
      expect(sanitized).to eq(hash_sanitized)
    end

    it "leaves a string alone that does not contain xss tags" do
      sanitized = helper.sanitized_props_string(hash_sanitized)
      expect(sanitized).to eq(hash_sanitized)
    end

    it "fixes a string alone that contain xss tags" do
      sanitized = helper.sanitized_props_string(hash_unsanitized)
      expect(sanitized).to eq(hash_sanitized)
    end
  end

  describe "#react_component" do
    subject { react_component("App", props: props) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_component_div) do
      "<div id=\"App-react-component-0\"></div>"
    end

    let(:id) { "App-react-component-0" }

    let(:react_definition_div) do
      %(<div class="js-react-on-rails-component"
            style="display:none"
            data-component-name="App"
            data-props="{&quot;name&quot;:&quot;My Test Name&quot;}"
            data-trace="false"
            data-dom-id="#{id}"></div>).squish
    end

    let(:react_definition_div_no_params) do
      %(<div class="js-react-on-rails-component"
            style="display:none"
            data-component-name="App"
            data-props="{}"
            data-trace="false"
            data-dom-id="#{id}"></div>).squish
    end

    describe "deprecated API" do
      subject { react_component("App", props) }
      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }
      it { is_expected.to include react_definition_div }
    end

    describe "API with component name only" do
      subject { react_component("App") }
      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }
      it { is_expected.to include react_definition_div_no_params }
    end

    describe "Deprecated API with component name and empty props" do
      subject { react_component("App", "") }
      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }
      it { is_expected.to include react_definition_div_no_params }
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<div" }
    it { is_expected.to match %r{</div>\s*$} }
    it { is_expected.to include react_component_div }
    it { is_expected.to include react_definition_div }

    context "with 'id' option" do
      subject { react_component("App", props: props, id: id) }

      let(:id) { "shaka_div" }

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_div }
      it { is_expected.to include react_definition_div }
    end

    context "with skip_display_none option true" do
      before { ReactOnRails.configuration.skip_display_none = true }

      let(:react_definition_div_skip_display_none_true) do
        "<div class=\"js-react-on-rails-component\"
              data-component-name=\"App\"
              data-props=\"{&quot;name&quot;:&quot;My Test Name&quot;}\"
              data-trace=\"false\"
              data-dom-id=\"#{id}\"></div>".squish
      end

      it { is_expected.to include react_definition_div_skip_display_none_true }
    end

    context "with skip_display_none option false" do
      before { ReactOnRails.configuration.skip_display_none = false }

      let(:react_definition_div_skip_display_none_false) do
        "<div class=\"js-react-on-rails-component\"
              style=\"display:none\"
              data-component-name=\"App\"
              data-props=\"{&quot;name&quot;:&quot;My Test Name&quot;}\"
              data-trace=\"false\"
              data-dom-id=\"#{id}\"></div>".squish
      end

      it { is_expected.to include react_definition_div_skip_display_none_false }
    end
  end

  describe "#redux_store" do
    subject { redux_store("reduxStore", props: props) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_store_div) do
      %(<div class="js-react-on-rails-store"
            style="display:none"
            data-store-name="reduxStore"
            data-props="{&quot;name&quot;:&quot;My Test Name&quot;}"></div>).squish
    end

    it { expect(self).to respond_to :redux_store }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<div" }
    it { is_expected.to end_with "</div>" }
    it { is_expected.to include react_store_div }

    context "with skip_display_none option true" do
      before { ReactOnRails.configuration.skip_display_none = true }

      let(:react_store_definition_div_skip_display_none_true) do
        %(<div class="js-react-on-rails-store"
            data-store-name="reduxStore"
            data-props="{&quot;name&quot;:&quot;My Test Name&quot;}"></div>).squish
      end

      it { is_expected.to include react_store_definition_div_skip_display_none_true }
    end

    context "with skip_display_none option false" do
      before { ReactOnRails.configuration.skip_display_none = false }
      it { is_expected.to include react_store_div }
    end
  end

  describe "#server_render_js" do
    subject { server_render_js("ReactOnRails.getComponent('HelloString').component.world()") }

    let(:hello_world) do
      "Hello WORLD! Will this work?? YES! Time to visit Maui"
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to eq hello_world }
  end
end
