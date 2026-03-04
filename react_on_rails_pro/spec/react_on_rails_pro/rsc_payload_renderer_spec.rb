# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRailsPro::RSCPayloadRenderer do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include ReactOnRailsPro::RSCPayloadRenderer
    end
  end
  let(:controller) { controller_class.new }

  describe "#rsc_payload" do
    before do
      allow(controller).to receive_messages(
        rsc_payload_component_name: "ReactServerComponentPage",
        rsc_payload_component_props: { "from" => "spec" }
      )
      allow(controller).to receive(:stream_view_containing_react_components)
    end

    it "uses streaming compression for rsc payload responses" do
      controller.rsc_payload

      expect(controller).to have_received(:stream_view_containing_react_components).with(
        template: "react_on_rails_pro/rsc_payload",
        compress: true,
        layout: false
      )
    end
  end
end
