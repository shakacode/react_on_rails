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
        start_gate_timeout: 30.0,
        upload_timeout: 10.0,
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

    it "warns and clears duration when applying the smoke preset" do
      config = nil

      expect do
        config = described_class.parse(["--duration", "1", "--smoke"])
      end.to output(/--smoke overrides --duration 1.0 with 10 requests/).to_stderr

      expect(config).to have_attributes(requests: 10, duration: nil)
    end

    it "parses the worker start-gate timeout" do
      config = described_class.parse(["--requests", "1", "--start-gate-timeout", "0.5"])

      expect(config.start_gate_timeout).to eq(0.5)
    end

    it "parses the bundle upload timeout" do
      config = described_class.parse(["--requests", "1", "--upload-timeout", "0.5"])

      expect(config.upload_timeout).to eq(0.5)
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

    it "rejects non-positive worker start-gate timeouts" do
      expect do
        described_class.parse(["--requests", "1", "--start-gate-timeout", "0"])
      end.to raise_error(ArgumentError, /--start-gate-timeout must be > 0/)
    end

    it "rejects non-positive bundle upload timeouts" do
      expect do
        described_class.parse(["--requests", "1", "--upload-timeout", "0"])
      end.to raise_error(ArgumentError, /--upload-timeout must be > 0/)
    end

    it "keeps parser helper methods private" do
      expect(described_class.private_methods).to include(:build_parser, :validate!)
      expect(described_class).not_to respond_to(:build_parser)
    end
  end
end
