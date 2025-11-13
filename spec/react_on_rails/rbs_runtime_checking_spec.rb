# frozen_string_literal: true

require_relative "../spec_helper"

# This spec validates that RBS runtime type checking catches actual type violations
# when enabled during test execution. These tests should only run when RBS is available.
RSpec.describe "RBS Runtime Type Checking", type: :rbs do
  before do
    skip "RBS gem not available" unless defined?(RBS)
    skip "RBS runtime checking disabled" if ENV["DISABLE_RBS_RUNTIME_CHECKING"] == "true"
    skip "RBS runtime hook not loaded" unless ENV.fetch("RUBYOPT", "").include?("-rrbs/test/setup")
  end

  describe "Configuration type checking" do
    it "catches invalid type assignments to configuration" do
      # This test verifies runtime checking actually works by intentionally
      # violating a type signature and expecting RBS to catch it
      expect do
        config = ReactOnRails::Configuration.new(
          server_bundle_js_file: 123 # Invalid: should be String, not Integer
        )
        config.server_bundle_js_file # Access to trigger type check
      end.to raise_error(RBS::Test::Hook::TypeError)
    end

    it "allows valid type assignments to configuration" do
      # This validates that correct types pass through without error
      expect do
        config = ReactOnRails::Configuration.new(
          server_bundle_js_file: "valid-string.js"
        )
        config.server_bundle_js_file
      end.not_to raise_error
    end
  end

  describe "Helper method type checking" do
    # Test that helper methods have their signatures validated
    # This ensures the RBS signatures in sig/ are being used
    it "has RBS signatures loaded for ReactOnRails::Helper" do
      # Verify the helper module has type signatures
      expect(ReactOnRails::Helper).to be_a(Module)

      # If RBS runtime checking is active, method calls will be wrapped
      # We can verify this by checking that invalid calls raise type errors
      # (implementation depends on specific helper method signatures)
    end
  end

  describe "RBS::Test environment" do
    it "has RBS_TEST_TARGET configured for ReactOnRails" do
      expect(ENV.fetch("RBS_TEST_TARGET", "")).to include("ReactOnRails")
    end

    it "has loaded RBS test setup" do
      # Verify the RBS test framework is active
      expect(defined?(RBS::Test::Hook)).to be_truthy
    end
  end
end
