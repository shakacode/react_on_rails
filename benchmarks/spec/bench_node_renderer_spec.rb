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
  def process_status(success:, exitstatus: nil, termsig: nil)
    instance_double(Process::Status, success?: success, exitstatus:, termsig:)
  end

  describe "#validate_node_renderer_benchmark_config!" do
    it "rejects more load-generator shards than available Vegeta workers" do
      stub_const("LOAD_GENERATOR_SHARDS", CONNECTIONS + 1)

      expect { validate_node_renderer_benchmark_config! }
        .to raise_error(/LOAD_GENERATOR_SHARDS must be no greater than CONNECTIONS and MAX_CONNECTIONS/)
    end

    it "rejects fixed rates that would round to unlimited Vegeta rate with one shard" do
      stub_const("LOAD_GENERATOR_SHARDS", 1)
      stub_const("RATE", "0.0000004")

      expect { validate_node_renderer_benchmark_config! }
        .to raise_error(/RATE must be at least 0\.000001 when LOAD_GENERATOR_SHARDS=1/)
    end

    it "rejects fixed rates whose per-shard request period exceeds the benchmark duration" do
      stub_const("LOAD_GENERATOR_SHARDS", 1)
      stub_const("RATE", "0.000001")
      stub_const("DURATION", "30s")

      expect { validate_node_renderer_benchmark_config! }
        .to raise_error(/RATE must be at least 0\.033334 when LOAD_GENERATOR_SHARDS=1 and DURATION=30s/)
    end

    it "rejects zero duration for fixed-rate Vegeta benchmarks" do
      stub_const("LOAD_GENERATOR_SHARDS", 1)
      stub_const("RATE", "1")
      stub_const("DURATION", "0s")

      expect { validate_node_renderer_benchmark_config! }
        .to raise_error(/DURATION must be greater than 0 for fixed RATE/)
    end

    it "accepts fixed rates that schedule at least one request per shard within the benchmark duration" do
      stub_const("LOAD_GENERATOR_SHARDS", 1)
      stub_const("RATE", "0.033334")
      stub_const("DURATION", "30s")

      expect { validate_node_renderer_benchmark_config! }.not_to raise_error
    end
  end

  describe "#vegeta_rates_for_shards" do
    it "distributes fixed-rate remainder across shards using Vegeta-compatible syntax" do
      stub_const("RATE", "1")

      expect(vegeta_rates_for_shards(3)).to eq(%w[333334/1000000s 333333/1000000s 333333/1000000s])
    end

    it "keeps evenly divisible fixed rates as integer rates" do
      stub_const("RATE", "9")

      expect(vegeta_rates_for_shards(3)).to eq(%w[3 3 3])
    end
  end

  describe "#run_vegeta_suite" do
    # Minimal stand-in for BmfCollector that records exactly what would ship to
    # Bencher, so the specs can assert failed tests never reach the payload.
    let(:collector) do
      Class.new do
        attr_reader :added

        def initialize
          @added = []
        end

        def add(name:, rps:, p50:, status:, p90: nil)
          @added << { name:, rps:, p50:, p90:, status: }
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

      failed = run_vegeta_suite(test_cases, "bundleX", "non-RSC", collector, runner:)

      expect(failed).to be_empty
      expect(collector.added.map { |m| m[:name] }).to eq(["simple_eval (non-RSC)", "react_ssr (non-RSC)"])
    end

    it "continues past a failing test and returns every test that failed" do
      # simple_eval is first in test_cases, so failing it proves the suite keeps
      # going and still records react_ssr (which runs after the failure).
      runner = lambda do |test_case, _bundle|
        raise "Vegeta attack failed for #{test_case[:name]}" if test_case[:name] == "simple_eval"

        [100.0, 1.0, 2.0, "200=10"]
      end

      failed = nil
      # ::error:: annotations go to stdout so GitHub Actions renders them.
      expect { failed = run_vegeta_suite(test_cases, "bundleX", "RSC", collector, runner:) }
        .to output(/::error::.*simple_eval/).to_stdout

      expect(failed).to eq(["simple_eval (RSC)"])
      # The test after the failure (react_ssr) still ran and was recorded — no early abort.
      expect(collector.added.map { |m| m[:name] }).to eq(["react_ssr (RSC)"])
    end

    it "keeps fabricated metrics out of the Bencher payload for failed tests" do
      runner = ->(_test_case, _bundle) { raise "Vegeta attack failed" }

      failed = nil
      # Pin both tests' ::error:: annotations (in order) on stdout rather than
      # accepting any output, so a dropped or reformatted annotation is caught.
      expect { failed = run_vegeta_suite(test_cases, "bundleX", "non-RSC", collector, runner:) }
        .to output(/::error::.*simple_eval.*::error::.*react_ssr/m).to_stdout

      expect(failed).to eq(["simple_eval (non-RSC)", "react_ssr (non-RSC)"])
      expect(collector.added).to be_empty
    end
  end

  describe "#run_vegeta_benchmark" do
    it "runs all shards concurrently before merging their result streams into one Vegeta report" do
      stub_const("CONNECTIONS", 10)
      stub_const("MAX_CONNECTIONS", 10)
      stub_const("RATE", "max")
      stub_const("DURATION", "30s")

      events = []
      spawned_commands = []

      allow(File).to receive(:write)
      allow(FileUtils).to receive(:rm_f)
      allow(Process).to receive(:spawn) do |command|
        events << :spawn
        spawned_commands << command
        spawned_commands.length
      end
      allow(Process).to receive(:wait2) do |pid|
        events << :wait
        [pid, process_status(success: true)]
      end
      allow(self).to receive_messages(system: true, parse_json_file: { "throughput" => 123.456,
                                                                       "latencies" => { "50th" => 1_500_000,
                                                                                        "90th" => 2_500_000 },
                                                                       "status_codes" => { "200" => 30 } })

      result = run_vegeta_benchmark({ name: "simple_eval", request: "2+2" }, "bundleX", shard_count: 3)

      expect(result).to eq([123.46, 1.5, 2.5, "200=30"])
      expect(events).to eq(%i[spawn spawn spawn wait wait wait])
      expect(spawned_commands).to contain_exactly(
        a_string_matching(/vegeta attack .* -workers=4 -max-workers=4 .*simple_eval_vegeta_shard_1_of_3\.bin/),
        a_string_matching(/vegeta attack .* -workers=3 -max-workers=3 .*simple_eval_vegeta_shard_2_of_3\.bin/),
        a_string_matching(/vegeta attack .* -workers=3 -max-workers=3 .*simple_eval_vegeta_shard_3_of_3\.bin/)
      )
      shard_result_files = [
        "simple_eval_vegeta_shard_1_of_3.bin",
        "simple_eval_vegeta_shard_2_of_3.bin",
        "simple_eval_vegeta_shard_3_of_3.bin"
      ]
      expect(self).to have_received(:system).with(
        "bash",
        "-c",
        a_string_including("set -o pipefail; vegeta report", *shard_result_files, "| tee")
      )
      expect(self).to have_received(:system).with(
        "bash",
        "-c",
        a_string_including(
          "set -o pipefail; vegeta report #{Shellwords.escape('-type=json')}",
          *shard_result_files,
          ">"
        )
      )
      expect(FileUtils).to have_received(:rm_f).with(
        contain_exactly(
          a_string_matching(/simple_eval_vegeta_shard_1_of_3\.bin/),
          a_string_matching(/simple_eval_vegeta_shard_2_of_3\.bin/),
          a_string_matching(/simple_eval_vegeta_shard_3_of_3\.bin/)
        )
      )
    end

    it "raises before reporting or parsing when a shard attack fails" do
      allow(File).to receive(:write)
      allow(FileUtils).to receive(:rm_f)
      next_pid = 0
      allow(Process).to receive(:spawn) do |_command|
        next_pid += 1
      end
      allow(Process).to receive(:wait2) do |pid|
        status = pid == 2 ? process_status(success: false, exitstatus: 1) : process_status(success: true)
        [pid, status]
      end
      allow(self).to receive(:system)
      allow(self).to receive(:parse_json_file)

      expect { run_vegeta_benchmark({ name: "simple_eval", request: "2+2" }, "bundleX", shard_count: 3) }
        .to raise_error(%r{Vegeta attack failed for simple_eval: shard 2/3 exited with status 1})

      expect(self).not_to have_received(:system).with("bash", "-c", /vegeta report/)
      expect(self).not_to have_received(:parse_json_file)
      expect(FileUtils).to have_received(:rm_f).with(
        contain_exactly(
          a_string_matching(/simple_eval_vegeta_shard_1_of_3\.bin/),
          a_string_matching(/simple_eval_vegeta_shard_2_of_3\.bin/),
          a_string_matching(/simple_eval_vegeta_shard_3_of_3\.bin/)
        )
      )
    end
  end
end
