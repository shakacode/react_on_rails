# frozen_string_literal: true

require "spec_helper"
require "react_on_rails/controller"
require "react_on_rails/helper"

RSpec.describe ReactOnRails::Controller do
  subject(:controller_instance) { controller_class.new }

  let(:controller_class) do
    Class.new do
      include ReactOnRails::Controller
    end
  end

  before do
    allow(Rails.logger).to receive(:warn)
    ReactOnRails::Helper.reset_removed_immediate_hydration_warnings!
  end

  describe "#redux_store" do
    it "accepts immediate_hydration and warns once" do
      controller_instance.redux_store("TestStore", props: { a: 1 }, immediate_hydration: true)
      controller_instance.redux_store("TestStore", props: { a: 2 }, immediate_hydration: false)

      expect(Rails.logger).to have_received(:warn).once.with(include("immediate_hydration"))
      expect(controller_instance.instance_variable_get(:@registered_stores_defer_render)).to eq(
        [
          { store_name: "TestStore", props: { a: 1 } },
          { store_name: "TestStore", props: { a: 2 } }
        ]
      )
    end
  end
end
