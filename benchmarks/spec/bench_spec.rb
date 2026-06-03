# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../bench"

# bench.rb runs its benchmark flow only under `if __FILE__ == $PROGRAM_NAME`, so
# requiring it just loads the helpers. These pin the per-route k6 failure
# handling: a single k6/parse failure must NOT abort the remaining routes, must
# NOT ship fabricated metrics to Bencher (via the BMF collector), and must be
# surfaced so the suite can exit non-zero instead of reporting a green run on
# fabricated data (#3459).
RSpec.describe "bench" do
  describe "#run_benchmark_suite" do
    # Minimal stand-in for BmfCollector that records exactly what would ship to
    # Bencher, so the specs can assert failed routes never reach the payload.
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

    before do
      # The human-readable summary file is a side effect covered by the workflow's
      # validate step; keep these specs focused on failure collection + payload.
      allow(self).to receive(:add_to_summary)
    end

    it "returns no failures and records every route when all succeed" do
      runner = ->(_route) { [100.0, 1.0, 2.0, "200=10"] }

      failed = run_benchmark_suite(%w[/a /b], collector, runner: runner)

      expect(failed).to be_empty
      expect(collector.added.map { |m| m[:name] }).to eq(%w[/a /b])
    end

    it "continues past a failing route and returns every route that failed" do
      runner = lambda do |route|
        raise "k6 benchmark failed" if route == "/bad"

        [100.0, 1.0, 2.0, "200=10"]
      end

      failed = nil
      expect { failed = run_benchmark_suite(%w[/a /bad /c], collector, runner: runner) }
        .to output(%r{::error::.*/bad}).to_stderr

      expect(failed).to eq(["/bad"])
      # The routes after the failure still ran (no early abort).
      expect(collector.added.map { |m| m[:name] }).to eq(%w[/a /c])
    end

    it "keeps fabricated metrics out of the Bencher payload for failed routes" do
      runner = ->(_route) { raise "k6 benchmark failed" }

      failed = nil
      expect { failed = run_benchmark_suite(%w[/x /y], collector, runner: runner) }
        .to output.to_stderr

      expect(failed).to eq(%w[/x /y])
      expect(collector.added).to be_empty
    end
  end
end
