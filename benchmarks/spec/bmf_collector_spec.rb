# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bmf_helpers"
require "tmpdir"

# BmfCollector produces the JSON Bencher ingests. The thresholded measures (rps,
# p50_latency, failed_pct) must stay in lockstep with track_benchmarks.rb's THRESHOLDS.
# p90_latency is also emitted but sent boundary-less (no threshold) so Bencher records its
# history and can supply a baseline for the summary table — it is never alerted on.
RSpec.describe BmfCollector do
  describe "#to_bmf" do
    it "emits rps, p50_latency and failed_pct (and p90_latency only when p90 is supplied)" do
      collector = described_class.new
      collector.add(name: "/route", rps: 100.0, p50: 5.0, status: "200=100")

      entry = collector.to_bmf.fetch("/route")
      expect(entry.keys).to contain_exactly("rps", "p50_latency", "failed_pct")
      expect(entry["rps"]).to eq("value" => 100.0)
      expect(entry["p50_latency"]).to eq("value" => 5.0)
    end

    it "emits p90_latency (boundary-less) when p90 is supplied" do
      collector = described_class.new
      collector.add(name: "/route", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")

      entry = collector.to_bmf.fetch("/route")
      expect(entry.keys).to contain_exactly("rps", "p50_latency", "p90_latency", "failed_pct")
      expect(entry["p90_latency"]).to eq("value" => 6.0)
    end

    it "omits p90_latency when p90 is not numeric" do
      collector = described_class.new
      collector.add(name: "/partial", rps: 100.0, p50: 5.0, p90: "MISSING", status: "200=100")

      expect(collector.to_bmf.fetch("/partial")).not_to have_key("p90_latency")
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
      collector.add(name: "/x", rps: 1.0, p50: 1.0, status:)
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

  # The display sidecar carries the summary-table columns keyed by the same canonical
  # name the BMF uses, so track_benchmarks.rb joins it with the Bencher report exactly (no
  # name reconstruction). It still carries the raw Status string (Bencher never sees it)
  # and keeps failed rows visible even though to_bmf drops them. failed_pct is no longer
  # carried — the Fail% column was dropped (issue #3601 item 4), so nothing reads it.
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

      it "stores nil for non-numeric p50/p90 and keeps failed rows with their raw rps token" do
        collector = described_class.new
        collector.add(name: "/partial", rps: 100.0, p50: "MISSING", p90: "MISSING", status: "200=100")
        collector.add(name: "/broken", rps: "FAILED", p50: "FAILED", p90: "FAILED", status: "Connection refused")

        expect(collector.display_rows).to eq(
          [{ "name" => "/partial", "rps" => 100.0, "p50" => nil, "p90" => nil, "status" => "200=100" },
           { "name" => "/broken", "rps" => "FAILED", "p50" => nil, "p90" => nil, "status" => "Connection refused" }]
        )
      end

      it "keeps a failed row visible in the sidecar even though to_bmf drops it" do
        collector = described_class.new
        collector.add(name: "/broken", rps: "FAILED", p50: "FAILED", p90: "FAILED", status: "Connection refused")

        expect(collector.display_rows.map { |row| row["name"] }).to eq(["/broken"])
        expect(collector.to_bmf).to be_empty
      end

      it "carries per-sample values in the row (and never in the BMF payload)" do
        samples = { "rps" => [99.0, 100.0, 101.0], "p50_latency" => [4.9, 5.0, 5.2] }
        collector = described_class.new
        collector.add(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100", samples:)

        expect(collector.display_rows.first["samples"]).to eq(samples)
        expect(collector.to_bmf.dig("/foo", "rps")).to eq("value" => 100.0)
        expect(collector.to_bmf["/foo"].keys).not_to include("samples")
      end

      it "omits the samples key for single-sample rows (nil or empty samples)" do
        collector = described_class.new
        collector.add(name: "/single", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100", samples: nil)
        collector.add(name: "/empty", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100", samples: {})

        expect(collector.display_rows).to(be_none { |row| row.key?("samples") })
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

      it "overwrites (keeping only new rows) when the existing file is a non-array JSON shape" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "display.json")
          File.write(path, JSON.generate("not" => "an array"))
          collector = described_class.new
          collector.add(name: "/new", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

          expect(collector.write_display_json(path, append: true)).to be(true)
          expect(JSON.parse(File.read(path)).map { |row| row["name"] }).to eq(["/new"])
        end
      end

      it "overwrites (keeping only new rows) when the existing file is invalid JSON" do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "display.json")
          File.write(path, "{not valid json")
          collector = described_class.new
          collector.add(name: "/new", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

          expect(collector.write_display_json(path, append: true)).to be(true)
          expect(JSON.parse(File.read(path)).map { |row| row["name"] }).to eq(["/new"])
        end
      end
    end
  end

  # p90 is sent to Bencher boundary-less: in the BMF (so a baseline can accrue) but never
  # in THRESHOLDS, so it is recorded yet never alerted on (issue #3601 item 3).
  describe "p90 reaches the BMF but is never thresholded" do
    it "is added to to_bmf as p90_latency when supplied" do
      collector = described_class.new
      collector.add(name: "/foo", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")

      expect(collector.to_bmf.fetch("/foo").keys).to contain_exactly("rps", "p50_latency", "p90_latency", "failed_pct")
    end
  end
end
