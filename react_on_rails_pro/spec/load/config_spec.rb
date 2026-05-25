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

    it "warns when smoke mode overrides an explicit scenario" do
      config = nil

      expect do
        config = described_class.parse(["--scenario", "streaming_render", "--smoke"])
      end.to output(/--smoke overrides --scenario streaming_render with standard_render/).to_stderr

      expect(config.scenario).to eq("standard_render")
    end

    it "clears duration when applying the smoke preset" do
      config = described_class.parse(["--duration", "1", "--smoke"])

      expect(config).to have_attributes(requests: 10, duration: nil)
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

    it "does not expose the unfinished incremental async scenario" do
      expect do
        described_class.parse(["--scenario", "incremental_async", "--requests", "1"])
      end.to raise_error(ArgumentError, /unknown scenario: incremental_async/)
    end

    it "keeps parser helper methods private" do
      expect(described_class.private_methods).to include(:build_parser, :validate!)
      expect(described_class).not_to respond_to(:build_parser)
    end
  end
end
