# frozen_string_literal: true

require_relative "spec_helper"
require "config"

RSpec.describe RendererHarness::Config do
  describe ".parse" do
    it "applies the smoke preset" do
      config = described_class.parse(["--smoke"])

      expect(config).to have_attributes(
        scenario: "standard_render",
        requests: 10,
        concurrency: 1,
        warmup: 0,
        smoke: true
      )
    end

    it "rejects mutually exclusive run modes" do
      expect do
        described_class.parse(["--requests", "10", "--duration", "1"])
      end.to raise_error(ArgumentError, /mutually exclusive/)
    end

    it "rejects unknown scenarios" do
      expect do
        described_class.parse(["--scenario", "missing", "--requests", "1"])
      end.to raise_error(ArgumentError, /unknown scenario: missing/)
    end
  end
end
