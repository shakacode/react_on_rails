# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::Summary do
  describe ".display_rows" do
    it "returns parsed display rows from a JSON array sidecar" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "benchmark_display.json")
        rows = [{ "name" => "/posts", "rps" => 10.0 }]
        File.write(path, JSON.generate(rows))

        expect(described_class.display_rows(path)).to eq(rows)
      end
    end

    it "warns and returns no rows when the sidecar is malformed JSON" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "benchmark_display.json")
        File.write(path, "{")

        rows = nil
        expect { rows = described_class.display_rows(path) }
          .to output(/::warning::Could not parse #{Regexp.escape(path)}/).to_stdout

        expect(rows).to eq([])
      end
    end
  end

  describe ".regressed_alert_pairs" do
    it "deduplicates active alert benchmark and measure pairs" do
      report = BencherReport.parse(
        JSON.generate(
          "results" => [],
          "alerts" => [
            {
              "benchmark" => { "name" => "/posts: Pro" },
              "threshold" => { "measure" => { "slug" => "rps" } },
              "status" => "active"
            },
            {
              "benchmark" => { "name" => "/posts: Pro" },
              "threshold" => { "measure" => { "slug" => "rps" } },
              "status" => "active"
            }
          ]
        )
      )

      expect(described_class.regressed_alert_pairs(report)).to eq(
        [{ "benchmark" => "/posts: Pro", "measure" => "rps" }]
      )
    end
  end
end
