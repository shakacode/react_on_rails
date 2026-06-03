# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../bench-node-renderer"

# bench-node-renderer.rb runs its benchmark flow only under
# `if __FILE__ == $PROGRAM_NAME`, so requiring it just loads the helpers. These
# pin the per-test Vegeta failure handling: a single failure must NOT abort the
# remaining tests, must NOT ship fabricated metrics to Bencher (via the BMF
# collector), and must be surfaced so the suite can exit non-zero instead of
# reporting a green run on fabricated data (#3459).
RSpec.describe "bench-node-renderer" do
  describe "#run_vegeta_suite" do
    # Minimal stand-in for BmfCollector that records exactly what would ship to
    # Bencher, so the specs can assert failed tests never reach the payload.
    let(:collector) do
      Class.new do
        attr_reader :added

        def initialize
          @added = []
        end

        def add(name:, rps:, p50:, status:)
          @added << { name: name, rps: rps, p50: p50, status: status }
        end
      end.new
    end

    let(:test_cases) do
      [{ name: "simple_eval", request: "2+2" }, { name: "react_ssr", request: "render(...)" }]
    end

    before do
      # The human-readable summary file is a side effect covered by the workflow's
      # validate step; keep these specs focused on failure collection + payload.
      allow(self).to receive(:add_to_summary)
    end

    it "returns no failures and records every test when all succeed" do
      runner = ->(_test_case, _bundle) { [100.0, 1.0, 2.0, "200=10"] }

      failed = run_vegeta_suite(test_cases, "bundleX", "non-RSC", collector, runner: runner)

      expect(failed).to be_empty
      expect(collector.added.map { |m| m[:name] }).to eq(["simple_eval (non-RSC)", "react_ssr (non-RSC)"])
    end

    it "continues past a failing test and returns every test that failed" do
      runner = lambda do |test_case, _bundle|
        raise "Vegeta attack failed for #{test_case[:name]}" if test_case[:name] == "react_ssr"

        [100.0, 1.0, 2.0, "200=10"]
      end

      failed = nil
      # ::error:: annotations go to stdout so GitHub Actions renders them.
      expect { failed = run_vegeta_suite(test_cases, "bundleX", "RSC", collector, runner: runner) }
        .to output(/::error::.*react_ssr/).to_stdout

      expect(failed).to eq(["react_ssr (RSC)"])
      # The test after the failure still ran (no early abort).
      expect(collector.added.map { |m| m[:name] }).to eq(["simple_eval (RSC)"])
    end

    it "keeps fabricated metrics out of the Bencher payload for failed tests" do
      runner = ->(_test_case, _bundle) { raise "Vegeta attack failed" }

      failed = nil
      # Pin both tests' ::error:: annotations (in order) on stdout rather than
      # accepting any output, so a dropped or reformatted annotation is caught.
      expect { failed = run_vegeta_suite(test_cases, "bundleX", "non-RSC", collector, runner: runner) }
        .to output(/::error::.*simple_eval.*::error::.*react_ssr/m).to_stdout

      expect(failed).to eq(["simple_eval (non-RSC)", "react_ssr (non-RSC)"])
      expect(collector.added).to be_empty
    end
  end
end
