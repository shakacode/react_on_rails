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
      #
      # add_to_summary is a top-level `def`, which Ruby defines as a private
      # method on Object. run_benchmark_suite calls it with an implicit receiver,
      # so `self` resolves to this RSpec example instance — the same object the
      # before/it blocks run on — and this stub intercepts the call.
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
      # The failed route is recorded in the summary with FAILED placeholders and
      # the error message — never numeric (fabricated) metrics.
      expect(self).to have_received(:add_to_summary)
        .with("/bad", "FAILED", "FAILED", "FAILED", "k6 benchmark failed")
    end

    it "keeps fabricated metrics out of the Bencher payload for failed routes" do
      runner = ->(_route) { raise "k6 benchmark failed" }

      failed = nil
      # Pin both routes' ::error:: annotations (in order) rather than accepting
      # any stderr output, so a dropped or reformatted annotation is caught.
      expect { failed = run_benchmark_suite(%w[/x /y], collector, runner: runner) }
        .to output(%r{::error::.*/x.*::error::.*/y}m).to_stderr

      expect(failed).to eq(%w[/x /y])
      expect(collector.added).to be_empty
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
