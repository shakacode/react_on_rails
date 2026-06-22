# frozen_string_literal: true

module TrackBenchmarks
  # Resolves the Bencher branch and start-point arguments for each GitHub event.
  module BranchArgs
    module_function

    # A confirmation rerun (BENCHMARK_MODE=confirm) re-tests a main-push regression candidate
    # on a fresh runner before the issue is filed. It must NOT pollute main's Bencher series,
    # so it submits to a throwaway per-run branch and re-tests against main's cloned baseline.
    def confirmation_mode?(env: ENV)
      env.fetch("BENCHMARK_MODE", "initial") == "confirm"
    end

    # Bencher branch-safe slug: lowercase, runs of non-alphanumerics collapsed to a single
    # dash, no leading/trailing dash. "Pro (shard 1/2)" -> "pro-shard-1-2".
    def slugify(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    # A unique synthetic Bencher branch for the confirmation rerun, e.g.
    # "confirm-main-123456-pro-shard-1-2". Unique per run AND suite/shard so concurrent
    # confirmation reruns never share a series, and never "main" so the confirmation sample
    # is not appended to main's history.
    def confirmation_branch(run_id, suite_name)
      "confirm-main-#{run_id}-#{slugify(suite_name)}"
    end

    # Re-test against main's baseline without writing into main's series: clone main's
    # thresholds onto the throwaway branch and reset it to a fresh copy of main's head each
    # run. This is the same anchoring the PR path uses (branch_and_start_point_args).
    def confirmation_start_point_args
      ["--start-point", "main", "--start-point-clone-thresholds", "--start-point-reset"]
    end

    def branch_and_start_point_args(env: ENV)
      if confirmation_mode?(env:)
        return [
          confirmation_branch(env.fetch("GITHUB_RUN_ID"), env.fetch("BENCHMARK_SUITE_NAME")),
          confirmation_start_point_args
        ]
      end

      case env.fetch("GITHUB_EVENT_NAME")
      when "push"
        ["main", []]
      when "pull_request"
        [
          env.fetch("GITHUB_HEAD_REF"),
          [
            "--start-point", env.fetch("GITHUB_BASE_REF"),
            "--start-point-hash", env.fetch("GITHUB_BASE_SHA"),
            "--start-point-clone-thresholds",
            "--start-point-reset"
          ]
        ]
      when "workflow_dispatch"
        workflow_dispatch_args(env)
      else
        warn "Unexpected event type: #{env.fetch('GITHUB_EVENT_NAME')}"
        exit 1
      end
    end

    def workflow_dispatch_args(env)
      branch = env.fetch("GITHUB_REF_NAME")
      return [branch, []] if branch == "main"

      stdout, status = GithubCli.capture(
        "gh", "api", "repos/#{env.fetch('GITHUB_REPOSITORY')}/compare/main...#{branch}",
        "--jq", ".merge_base_commit.sha",
        error_message: "Failed to resolve merge-base with main for #{branch}"
      )
      start_point_args = ["--start-point", "main", "--start-point-clone-thresholds", "--start-point-reset"]
      # On API failure GithubCli already emits ::error::; fall back to the latest
      # baseline rather than conflating a failed call with "no merge-base found".
      merge_base = status.success? ? stdout.strip : ""

      if merge_base.empty?
        puts "Could not find merge-base with main via GitHub API, continuing without hash"
      else
        puts "Found merge-base via API: #{merge_base}"
        start_point_args.insert(2, "--start-point-hash", merge_base)
      end

      [branch, start_point_args]
    end
    private_class_method :workflow_dispatch_args
  end
end
