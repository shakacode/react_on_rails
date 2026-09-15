# frozen_string_literal: true

module TrackBenchmarks
  # Resolves the Bencher branches for relative continuous benchmarking (#3492,
  # https://bencher.dev/docs/how-to/track-benchmarks/#relative-continuous-benchmarking).
  #
  # Every tracking run submits TWO reports measured on the SAME runner:
  #   1. the base ref's results to a throwaway per-run baseline branch
  #      (--start-point-reset: a fresh series, nothing from other runners), then
  #   2. the head ref's results to the event's branch, compared against that baseline
  #      via --start-point <baseline> --start-point-reset and percentage thresholds
  #      (BencherRunner mode :relative_head).
  # The side-by-side comparison replaces the old statistical baseline built from
  # main's history across runners, whose cross-runner variance drowned the signal on
  # shared GitHub-hosted runners (#4071).
  module BranchArgs
    RunPlan = Struct.new(:baseline_branch, :head_branch, keyword_init: true)

    module_function

    # A confirmation rerun (BENCHMARK_MODE=confirm) re-runs a main-push regression
    # candidate's relative comparison on a fresh runner before the issue is filed. It
    # must NOT pollute main's Bencher series, so its head report goes to a throwaway
    # per-run branch.
    def confirmation_mode?(env: ENV)
      env.fetch("BENCHMARK_MODE", "initial") == "confirm"
    end

    # Bencher branch-safe slug: lowercase, runs of non-alphanumerics collapsed to a single
    # dash, no leading/trailing dash. "Pro (shard 1/2)" -> "pro-shard-1-2".
    def slugify(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    # A unique synthetic Bencher branch for the confirmation rerun's head report, e.g.
    # "confirm-main-123456-pro-shard-1-2". Unique per run AND suite/shard so concurrent
    # confirmation reruns never share a series, and never "main" so the confirmation
    # sample is not appended to main's history.
    def confirmation_branch(run_id, suite_name)
      "confirm-main-#{run_id}-#{slugify(suite_name)}"
    end

    # The throwaway branch holding this run's same-runner baseline. Unique per run AND
    # suite/shard: --start-point <branch> clones the branch's CURRENT head, so a name
    # shared between concurrently-running shards could compare one shard's head results
    # against another shard's baseline data (whose benchmark names don't even overlap,
    # silently disabling detection). The confirmation rerun gets its own prefix so it
    # can never collide with the initial run's baseline within the same workflow run.
    def baseline_branch(env: ENV)
      prefix = confirmation_mode?(env:) ? "confirm-base" : "base"
      "#{prefix}-#{env.fetch('GITHUB_RUN_ID')}-#{slugify(env.fetch('BENCHMARK_SUITE_NAME'))}"
    end

    def run_plan(env: ENV)
      RunPlan.new(baseline_branch: baseline_branch(env:), head_branch: head_branch(env:))
    end

    # Where the head ref's results are reported: the event's real branch ("main" for
    # pushes, the PR branch, the dispatched ref), or the throwaway confirmation branch.
    # Note the relative flow resets that branch to the per-run baseline every run, so
    # dashboard series no longer accumulate history on GitHub-hosted runners — the
    # long-term trend lives on the dedicated local-runner testbed instead (#4073).
    def head_branch(env: ENV)
      if confirmation_mode?(env:)
        return confirmation_branch(env.fetch("GITHUB_RUN_ID"), env.fetch("BENCHMARK_SUITE_NAME"))
      end

      case env.fetch("GITHUB_EVENT_NAME")
      when "push"
        "main"
      when "pull_request"
        env.fetch("GITHUB_HEAD_REF")
      when "workflow_dispatch"
        env.fetch("GITHUB_REF_NAME")
      else
        warn "Unexpected event type: #{env.fetch('GITHUB_EVENT_NAME')}"
        exit 1
      end
    end

    # The baseline run starts a fresh series even when a rerun reuses the branch name.
    def baseline_start_point_args
      ["--start-point-reset"]
    end

    # The head run is anchored to the just-recorded baseline. No
    # --start-point-clone-thresholds: relative thresholds are (re)stated on every run
    # by BencherRunner mode :relative_head, and no --start-point-hash: the baseline
    # branch's head IS the exact data this runner just measured.
    def head_start_point_args(baseline_branch)
      ["--start-point", baseline_branch, "--start-point-reset"]
    end
  end
end
