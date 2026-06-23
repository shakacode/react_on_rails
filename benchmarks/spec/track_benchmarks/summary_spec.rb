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

    it "preserves silent absent-file behavior" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "missing_display.json")

        rows = nil
        expect { rows = described_class.display_rows(path) }.not_to output.to_stdout

        expect(rows).to eq([])
      end
    end

    it "warns and returns no rows when the sidecar disappears after the existence check" do
      path = "benchmark_display.json"
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_raise(Errno::ENOENT)

      rows = nil
      expect { rows = described_class.display_rows(path) }
        .to output(/::warning::Could not read #{Regexp.escape(path)} \(Errno::ENOENT:/).to_stdout

      expect(rows).to eq([])
    end

    it "warns and returns no rows when the sidecar cannot be read because of permissions" do
      path = "benchmark_display.json"
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_raise(Errno::EACCES)

      rows = nil
      expect { rows = described_class.display_rows(path) }
        .to output(/::warning::Could not read #{Regexp.escape(path)} \(Errno::EACCES:/).to_stdout

      expect(rows).to eq([])
    end

    it "warns and returns no rows for other sidecar IO errors" do
      path = "benchmark_display.json"
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_raise(Errno::EIO)

      rows = nil
      expect { rows = described_class.display_rows(path) }
        .to output(/::warning::Could not read #{Regexp.escape(path)} \(Errno::EIO:/).to_stdout

      expect(rows).to eq([])
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
