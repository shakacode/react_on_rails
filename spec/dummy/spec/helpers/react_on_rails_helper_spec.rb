require "rails_helper"

describe ReactOnRailsHelper, type: :helper do
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
    subject { react_component("App", props) }

    let(:props) do
      { name: "My Test Name" }
    end

    let(:react_component_div) do
      "<div id=\"App-react-component-0\"></div>"
    end

    let(:id) { "App-react-component-0" }

    let(:react_definition_div) do
      "<div class=\"js-react-on-rails-component\"
            style=\"display:none\"
            data-component-name=\"App\"
            data-props=\"{&quot;name&quot;:&quot;My Test Name&quot;}\"
            data-trace=\"false\"
            data-generator-function=\"false\"
            data-expect-turbolinks=\"true\"
            data-dom-id=\"#{id}\"></div>".squish
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<div" }
    it { is_expected.to end_with "</div>\n\n" }
    it { is_expected.to include react_component_div }
    it { is_expected.to include react_definition_div }

    context "with 'id' option" do
      subject { react_component("App", props, id: id) }

      let(:id) { "shaka_div" }

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_div }
      it { is_expected.to include react_definition_div }
    end
  end

  describe "#server_render_js" do
    subject { server_render_js("this.HelloString.world()") }

    let(:hello_world) do
      "Hello WORLD! Will this work?? YES! Time to visit Maui"
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to eq hello_world }
  end
end
