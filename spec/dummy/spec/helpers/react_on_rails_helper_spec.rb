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
    before { allow(SecureRandom).to receive(:uuid).and_return(0, 1, 2, 3) }

    subject { react_component("App", props: props).squish }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_component_div) do
      "<div id=\"App-react-component-0\"></div>"
    end

    let(:id) { "App-react-component-0" }

    let(:react_definition_script) do
      %(<script class="js-react-on-rails-component"
            style="display:none"
            data-component-name="App"
            data-trace="false"
            data-dom-id="#{id}">var #{id.tr('-', '_')} = {"name":"My Test Name"};</script>).squish
    end

    let(:react_definition_div_no_params) do
      %(<script class="js-react-on-rails-component"
            style="display:none"
            data-component-name="App"
            data-trace="false"
            data-dom-id="#{id}">var #{id.tr('-', '_')} = {};</script>).squish
    end

    describe "API with component name only" do
      subject { react_component("App").squish }
      it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
      it { is_expected.to include react_component_div }
      it { is_expected.to include react_definition_div_no_params }
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<script" }
    it { is_expected.to match %r{</script>\s*$} }
    it { is_expected.to include react_component_div }
    it { is_expected.to include react_definition_script }

    context "with 'id' option" do
      subject { react_component("App", props: props, id: id) }

      let(:id) { "shaka_script" }

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_div }
      it { is_expected.to include react_definition_script }
    end

    context "with skip_display_none option true" do
      before { ReactOnRails.configuration.skip_display_none = true }

      let(:react_definition_script_skip_display_none_true) do
        "<script class=\"js-react-on-rails-component\"
              data-component-name=\"App\"
              data-trace=\"false\"
              data-dom-id=\"#{id}\">var #{id.tr('-', '_')} = {\"name\":\"My Test Name\"};</script>".squish
      end

      it { is_expected.to include react_definition_script_skip_display_none_true }
    end

    context "with skip_display_none option false" do
      before { ReactOnRails.configuration.skip_display_none = false }

      let(:react_definition_script_skip_display_none_false) do
        "<script class=\"js-react-on-rails-component\"
              style=\"display:none\"
              data-component-name=\"App\"
              data-trace=\"false\"
              data-dom-id=\"#{id}\">var #{id.tr('-', '_')} = {\"name\":\"My Test Name\"};</script>".squish
      end

      it { is_expected.to include react_definition_script_skip_display_none_false }
    end
  end

  describe "#redux_store" do
    subject { redux_store("reduxStore", props: props) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_store_script) do
      %(<script class="js-react-on-rails-store"
            style="display:none"
            data-store-name="reduxStore"
            data-props="{&quot;name&quot;:&quot;My Test Name&quot;}">var reduxStore = {"name":"My Test Name"};
      </script>).squish
    end

    it { expect(self).to respond_to :redux_store }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<script" }
    it { is_expected.to end_with "</script>" }
    it { is_expected.to include react_store_script }

    context "with skip_display_none option true" do
      before { ReactOnRails.configuration.skip_display_none = true }

      let(:react_store_definition_script_skip_display_none_true) do
        %(<script class="js-react-on-rails-store"
            data-store-name="reduxStore"
            data-props="{&quot;name&quot;:&quot;My Test Name&quot;}">var reduxStore = {"name":"My Test Name"};
        </script>).squish
      end

      it { is_expected.to include react_store_definition_script_skip_display_none_true }
    end

    context "with skip_display_none option false" do
      before { ReactOnRails.configuration.skip_display_none = false }
      it { is_expected.to include react_store_script }
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
