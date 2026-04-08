# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRails::RenderingStrategy do
  subject(:strategy) { strategy_class.new }

  let(:strategy_class) do
    Class.new do
      include ReactOnRails::RenderingStrategy
    end
  end

  describe "interface contract" do
    it "raises NotImplementedError for #execute" do
      expect { strategy.execute(double) }.to raise_error(NotImplementedError, /execute must be implemented/)
    end

    it "raises NotImplementedError for #execute_js" do
      expect { strategy.execute_js("code", double) }
        .to raise_error(NotImplementedError, /execute_js must be implemented/)
    end

    it "raises NotImplementedError for #reset" do
      expect { strategy.reset }.to raise_error(NotImplementedError, /reset must be implemented/)
    end

    it "raises NotImplementedError for #reset_if_bundle_changed" do
      expect { strategy.reset_if_bundle_changed }.to raise_error(
        NotImplementedError, /reset_if_bundle_changed must be implemented/
      )
    end
  end
end
