require "rails_helper"

describe ReactOnRailsHelper do
  describe "#react_component" do
    subject { react_component("App") }

    let(:react_component_div) do
      "<div id=\"App-react-component-0\"></div>"
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to start_with "<script>" }
    it { is_expected.to end_with "</div>\n\n" }
    it { is_expected.to include react_component_div }

    context "with 'id' option" do
      subject { react_component("App", {}, id: id) }

      let(:id) { "shaka_div" }

      it { is_expected.to include id }
      it { is_expected.not_to include react_component_div }
    end
  end

  describe "#render_js" do
    subject { render_js("this.HelloString.world()") }

    let(:hello_world) do
      "Hello WORLD! Will this work?? YES! Time to visit Maui\n"
    end

    it { expect(self).to respond_to :react_component }

    it { is_expected.to be_an_instance_of ActiveSupport::SafeBuffer }
    it { is_expected.to eq hello_world }
  end
end
