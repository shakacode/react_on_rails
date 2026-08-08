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

        def add(name:, rps:, p50:, status:, p90: nil, samples: nil)
          @added << { name:, rps:, p50:, p90:, status:, samples: }
        end
      end.new
    end

    before do
      # The human-readable summary file is a side effect covered by the workflow's
      # validate step; keep these specs focused on failure collection + payload.
      #
      # add_to_summary is a top-level `def`, which Ruby defines as a private
      # method on Object. run_benchmark_suite calls it with an implicit receiver,
      # so `self` resolves to this RSpec example instance — the same object the
      # before/it blocks run on — and this stub intercepts the call.
      allow(self).to receive(:add_to_summary)
    end

    it "returns no failures and records every route when all succeed" do
      runner = ->(_route) { { rps: 100.0, p50: 1.0, p90: 2.0, status: "200=10", samples: nil } }

      failed = run_benchmark_suite(%w[/a /b], collector, runner:)

      expect(failed).to be_empty
      expect(collector.added.map { |m| m[:name] }).to eq(%w[/a /b])
    end

    it "passes per-sample values through to the collector" do
      samples = { "rps" => [99.0, 100.0, 101.0] }
      runner = ->(_route) { { rps: 100.0, p50: 1.0, p90: 2.0, status: "200=10", samples: } }

      run_benchmark_suite(%w[/a], collector, runner:)

      expect(collector.added.first).to include(samples:)
    end

    it "continues past a failing route and returns every route that failed" do
      runner = lambda do |route|
        raise "k6 benchmark failed" if route == "/bad"

        { rps: 100.0, p50: 1.0, p90: 2.0, status: "200=10", samples: nil }
      end

      failed = nil
      # ::error:: annotations go to stdout so GitHub Actions renders them.
      expect { failed = run_benchmark_suite(%w[/a /bad /c], collector, runner:) }
        .to output(%r{::error::.*/bad}).to_stdout

      expect(failed).to eq(["/bad"])
      # The routes after the failure still ran (no early abort).
      expect(collector.added.map { |m| m[:name] }).to eq(%w[/a /c])
      # The failed route is recorded in the summary with FAILED placeholders and
      # the error message — never numeric (fabricated) metrics.
      expect(self).to have_received(:add_to_summary)
        .with("/bad", "FAILED", "FAILED", "FAILED", "k6 benchmark failed")
    end

    it "keeps fabricated metrics out of the Bencher payload for failed routes" do
      runner = ->(_route) { raise "k6 benchmark failed" }

      failed = nil
      # Pin both routes' ::error:: annotations (in order) rather than accepting
      # any stdout, so a dropped or reformatted annotation is caught. They go to
      # stdout so GitHub Actions renders them.
      expect { failed = run_benchmark_suite(%w[/x /y], collector, runner:) }
        .to output(%r{::error::.*/x.*::error::.*/y}m).to_stdout

      expect(failed).to eq(%w[/x /y])
      expect(collector.added).to be_empty
    end
  end

  # Sampling aggregation (#4580): repeated k6 samples per route are reduced to
  # medians (robust to a one-off noisy sample), summed status counts, and a raw
  # per-sample payload keyed by Bencher measure for sample confirmation.
  describe "#aggregate_samples" do
    it "reports the median per metric and keeps per-sample values by measure" do
      result = aggregate_samples(
        [
          [100.0, 10.0, 20.0, "200=100"],
          [130.0, 8.0, 26.0, "200=130"],
          [90.0, 11.0, 22.0, "200=90,3xx=1"]
        ]
      )

      expect(result).to eq(
        rps: 100.0, p50: 10.0, p90: 22.0, status: "200=320,3xx=1",
        samples: {
          "rps" => [100.0, 130.0, 90.0],
          "p50_latency" => [10.0, 8.0, 11.0],
          "p90_latency" => [20.0, 26.0, 22.0]
        }
      )
    end

    it "averages the middle two samples for even sample counts" do
      result = aggregate_samples([[100.0, 10.0, 20.0, "200=1"], [110.0, 12.0, 24.0, "200=1"]])

      expect(result[:rps]).to eq(105.0)
      expect(result[:p50]).to eq(11.0)
    end

    it "keeps the single-sample result unchanged with no samples payload" do
      result = aggregate_samples([[100.0, 10.0, 20.0, "200=100"]])

      expect(result).to eq(rps: 100.0, p50: 10.0, p90: 20.0, status: "200=100", samples: nil)
    end

    it "propagates MISSING for a metric any sample failed to produce, and drops it from samples" do
      result = aggregate_samples(
        [
          [100.0, 10.0, "MISSING", "200=100"],
          [110.0, 12.0, 24.0, "200=110"]
        ]
      )

      expect(result[:p90]).to eq("MISSING")
      expect(result[:rps]).to eq(105.0)
      expect(result[:samples]).to eq("rps" => [100.0, 110.0], "p50_latency" => [10.0, 12.0])
    end

    it "skips MISSING statuses when merging and stays MISSING when all are" do
      expect(aggregate_samples([[1.0, 1.0, 1.0, "MISSING"], [1.0, 1.0, 1.0, "200=5"]])[:status])
        .to eq("200=5")
      expect(aggregate_samples([[1.0, 1.0, 1.0, "MISSING"], [1.0, 1.0, 1.0, "MISSING"]])[:status])
        .to eq("MISSING")
    end
  end

  describe "#run_k6_benchmark" do
    # Regression for #3459: the k6 summary command is piped through `tee`, whose
    # always-zero exit status would otherwise mask a non-zero k6 exit. The
    # pipeline must run under pipefail (via bash) and any stale summary file from
    # a prior run must be removed first, so a k6 failure can never be parsed into
    # fabricated Bencher metrics.
    it "removes stale summaries, runs under pipefail, and raises without parsing on failure" do
      allow(FileUtils).to receive(:rm_f)
      # Model a failing k6 pipeline: with pipefail the bash invocation returns
      # non-zero even though tee succeeds.
      allow(self).to receive(:system).and_return(false)
      allow(self).to receive(:parse_json_file)

      expect { run_k6_benchmark("http://localhost:3001/x", "x") }
        .to raise_error(/k6 benchmark failed/)

      expect(FileUtils).to have_received(:rm_f).with(/_k6_summary\.json\z/)
      expect(self).to have_received(:system)
        .with("bash", "-c", a_string_matching(/\Aset -o pipefail; k6 run .* \| tee /))
      expect(self).not_to have_received(:parse_json_file)
    end
  end
end
