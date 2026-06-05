# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bencher_perf_url"

# BencherPerfUrl builds a benchmark's Bencher perf-plot URL from a parsed
# `bencher run --format json` report. Its entire contract is leniency: these fields are
# informational (they only decide whether a name hyperlinks), and the Bencher JSON shape is
# not a stability contract — so ANY missing/mis-typed piece must yield nil (an unlinked
# name), never raise and fail the benchmark job. These specs pin that never-raise promise
# directly; it is otherwise exercised only transitively through BencherReport#perf_url, so a
# future "tidy" of the guards could silently turn a cosmetic miss into an exception.
RSpec.describe BencherPerfUrl do
  # A well-formed report: top-level context + one benchmark with measures.
  def raw_with(results:, **overrides)
    {
      "uuid" => "R",
      "project" => { "slug" => "P" },
      "branch" => { "uuid" => "B", "head" => { "uuid" => "H" } },
      "testbed" => { "uuid" => "T" },
      "results" => results
    }.merge(overrides)
  end

  def bench(name: "/foo", uuid: "BM", measure_uuids: %w[M1 M2])
    measures = measure_uuids.map { |muuid| { "measure" => { "uuid" => muuid } } }
    { "benchmark" => { "name" => name, "uuid" => uuid }, "measures" => measures }
  end

  describe "#for_benchmark" do
    it "builds the URL from the report-wide context and the per-benchmark ids" do
      url = described_class.new(raw_with(results: [[bench]])).for_benchmark("/foo")
      expect(url).to eq(
        "https://bencher.dev/perf/P?branches=B&heads=H&testbeds=T&benchmarks=BM&measures=M1,M2&report=R"
      )
    end

    it "collapses duplicate measure uuids (.uniq) to a single list entry" do
      raw = raw_with(results: [[bench(measure_uuids: %w[M1 M1 M2])]])
      expect(described_class.new(raw).for_benchmark("/foo")).to include("measures=M1,M2&")
    end
  end

  # The leniency contract: each malformed shape must yield nil WITHOUT raising, so a cosmetic
  # link miss never escalates to a thrown exception during report rendering.
  describe "never raises on a malformed report (returns nil → unlinked name)" do
    it "when constructed with a non-Hash raw" do
      expect { described_class.new("not a hash") }.not_to raise_error
      expect(described_class.new(nil).for_benchmark("/foo")).to be_nil
    end

    it "when results is not an array" do
      raw = raw_with(results: { "not" => "an array" })
      expect(described_class.new(raw).for_benchmark("/foo")).to be_nil
    end

    it "when an iteration entry is not an array" do
      expect(described_class.new(raw_with(results: ["not an array"])).for_benchmark("/foo")).to be_nil
    end

    it "when a result element is not a hash" do
      expect(described_class.new(raw_with(results: [["not a hash"]])).for_benchmark("/foo")).to be_nil
    end

    it "when a benchmark's measures is not an array" do
      result = { "benchmark" => { "name" => "/foo", "uuid" => "BM" }, "measures" => "nope" }
      expect(described_class.new(raw_with(results: [[result]])).for_benchmark("/foo")).to be_nil
    end

    it "when a measure entry is not a hash" do
      result = { "benchmark" => { "name" => "/foo", "uuid" => "BM" }, "measures" => ["nope"] }
      expect(described_class.new(raw_with(results: [[result]])).for_benchmark("/foo")).to be_nil
    end

    it "when every measure uuid is a non-string (number/null), so none is usable" do
      measures = [{ "measure" => { "uuid" => 123 } }, { "measure" => { "uuid" => nil } }]
      result = { "benchmark" => { "name" => "/foo", "uuid" => "BM" }, "measures" => measures }
      # No usable measure uuid → not ready → nil (rather than "measures=123" or a raise).
      expect(described_class.new(raw_with(results: [[result]])).for_benchmark("/foo")).to be_nil
    end

    it "when a required context id (testbed) is a non-string" do
      raw = raw_with(results: [[bench]], "testbed" => { "uuid" => 42 })
      expect(described_class.new(raw).for_benchmark("/foo")).to be_nil
    end
  end

  # The report-wide context (project slug + branch & testbed uuids) is shared by every
  # benchmark's link: when it is usable the report can link them all, but if any id is
  # missing EVERY link degrades to an unlinked name. #context_ready? + #any_benchmarks? let
  # BencherReport surface that all-or-nothing drift as a ::warning:: (issue #3601 item 2
  # follow-up) without failing the job over a cosmetic link.
  describe "#context_ready? / #any_benchmarks?" do
    it "is ready and has benchmarks for a well-formed report" do
      perf = described_class.new(raw_with(results: [[bench]]))
      expect(perf.context_ready?).to be(true)
      expect(perf.any_benchmarks?).to be(true)
    end

    it "is not ready when a shared context id is missing, even though benchmarks exist" do
      raw = raw_with(results: [[bench]])
      raw["testbed"] = {}
      perf = described_class.new(raw)
      expect(perf.context_ready?).to be(false)
      expect(perf.any_benchmarks?).to be(true)
    end

    it "has no benchmarks when results is empty" do
      expect(described_class.new(raw_with(results: [])).any_benchmarks?).to be(false)
    end
  end
end
