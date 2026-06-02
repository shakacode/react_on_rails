# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bmf_helpers"

# BmfCollector produces the JSON Bencher ingests. Its measure names must stay in
# lockstep with track_benchmarks.rb's THRESHOLDS, so pin the emitted shape: the
# tracked measures rps, p50_latency, and failed_pct.
RSpec.describe BmfCollector do
  describe "#to_bmf" do
    it "emits exactly rps, p50_latency and failed_pct" do
      collector = described_class.new
      collector.add(name: "/route", rps: 100.0, p50: 5.0, status: "200=100")

      entry = collector.to_bmf.fetch("/route")
      expect(entry.keys).to contain_exactly("rps", "p50_latency", "failed_pct")
      expect(entry["rps"]).to eq("value" => 100.0)
      expect(entry["p50_latency"]).to eq("value" => 5.0)
    end

    it "applies the prefix and suffix to the benchmark name" do
      collector = described_class.new(prefix: "Pro Node Renderer: ", suffix: ": Pro")
      collector.add(name: "simple_eval", rps: 1.0, p50: 1.0, status: "200=1")

      expect(collector.to_bmf.keys).to eq(["Pro Node Renderer: simple_eval: Pro"])
    end

    it "drops rows whose rps is not numeric (FAILED/MISSING)" do
      collector = described_class.new
      collector.add(name: "/broken", rps: "FAILED", p50: "FAILED", status: "FAILED")

      expect(collector.to_bmf).to be_empty
    end

    it "omits p50_latency when p50 is not numeric" do
      collector = described_class.new
      collector.add(name: "/partial", rps: 100.0, p50: "MISSING", status: "200=100")

      entry = collector.to_bmf.fetch("/partial")
      expect(entry).to include("rps" => { "value" => 100.0 })
      expect(entry).not_to have_key("p50_latency")
    end
  end

  describe "failed_pct" do
    def failed_pct(status)
      collector = described_class.new
      collector.add(name: "/x", rps: 1.0, p50: 1.0, status: status)
      collector.to_bmf.dig("/x", "failed_pct", "value")
    end

    it "counts 0/4xx/5xx/other as failures and 2xx/3xx as success" do
      expect(failed_pct("200=98,5xx=2")).to eq(2.0)
      expect(failed_pct("200=900,302=50,404=40,503=10")).to eq(5.0)
      expect(failed_pct("0=5,200=95")).to eq(5.0)
    end

    it "is 0 for an all-success status and for MISSING/FAILED" do
      expect(failed_pct("200=100")).to eq(0.0)
      expect(failed_pct("MISSING")).to eq(0.0)
      expect(failed_pct("FAILED")).to eq(0.0)
    end
  end
end
