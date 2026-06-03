# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bmf_helpers"
require "tmpdir"

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

  # The display sidecar carries the columns the Markdown summary table needs but
  # that Bencher never sees: p90 and the human Status string. It is keyed by the
  # same canonical name the BMF uses, so track_benchmarks.rb joins it with the
  # Bencher report exactly (no name reconstruction).
  describe "display sidecar" do
    describe "#display_rows" do
      it "includes p90 and the raw status, keyed by the canonical (prefixed/suffixed) name" do
        collector = described_class.new(prefix: "Pro Node Renderer: ", suffix: ": Pro")
        collector.add(name: "simple_eval", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")

        expect(collector.display_rows).to eq(
          [{ "name" => "Pro Node Renderer: simple_eval: Pro", "rps" => 100.0,
             "p50" => 5.0, "p90" => 6.0, "status" => "200=100" }]
        )
      end

      it "stores nil for non-numeric p50/p90 and excludes rows with non-numeric rps" do
        collector = described_class.new
        collector.add(name: "/partial", rps: 100.0, p50: "MISSING", p90: "MISSING", status: "200=100")
        collector.add(name: "/broken", rps: "FAILED", p50: "FAILED", p90: "FAILED", status: "FAILED")

        expect(collector.display_rows).to eq(
          [{ "name" => "/partial", "rps" => 100.0, "p50" => nil, "p90" => nil, "status" => "200=100" }]
        )
      end
    end

    describe "#write_display_json" do
      it "writes the rows as a JSON array" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "display.json")
          collector = described_class.new
          collector.add(name: "/foo", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

          expect(collector.write_display_json(path)).to be(true)
          expect(JSON.parse(File.read(path))).to eq(
            [{ "name" => "/foo", "rps" => 1.0, "p50" => 2.0, "p90" => 3.0, "status" => "200=1" }]
          )
        end
      end

      it "appends to existing rows when append: true" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "display.json")
          File.write(path, JSON.generate([{ "name" => "/old", "rps" => 9.0, "p50" => nil,
                                            "p90" => nil, "status" => "200=1" }]))
          collector = described_class.new
          collector.add(name: "/new", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

          collector.write_display_json(path, append: true)
          names = JSON.parse(File.read(path)).map { |row| row["name"] }
          expect(names).to eq(["/old", "/new"])
        end
      end
    end
  end

  # p90 is summary-only: it must never become a tracked Bencher measure.
  describe "p90 stays out of the BMF output" do
    it "is not added to to_bmf even when supplied" do
      collector = described_class.new
      collector.add(name: "/foo", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

      expect(collector.to_bmf.fetch("/foo").keys).to contain_exactly("rps", "p50_latency", "failed_pct")
    end
  end
end
