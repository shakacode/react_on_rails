# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"
load SCRIPT

class PrMergeLedgerHostedCiTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_hosted_request_uses_selected_current_head_checks_even_when_required_gate_passed
    required_rows = [ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS")]
    hosted_rows = [
      ci_check("build", bucket: "pass", state: "SUCCESS").merge("workflow" => "Lint JS and Ruby"),
      ci_check("generators", bucket: "pending", state: "IN_PROGRESS").merge("workflow" => "Rspec test for gem")
    ]

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: required_rows,
      hosted_ci_requested: true,
      hosted_rows:,
      expected_hosted_workflows: ["Lint JS and Ruby", "Rspec test for gem"]
    )

    refute selection.fetch(:required_used)
    assert_equal required_rows + hosted_rows, selection.fetch(:rows)
    assert_match(/hosted CI requested/, selection.fetch(:message))
  end

  def test_hosted_request_is_unknown_until_every_selected_workflow_is_observed
    required_rows = [ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS")]
    hosted_rows = [
      ci_check("build", bucket: "pass", state: "SUCCESS").merge("workflow" => "Lint JS and Ruby")
    ]

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: required_rows,
      hosted_ci_requested: true,
      hosted_rows:,
      expected_hosted_workflows: ["Lint JS and Ruby", "Rspec test for gem"]
    )

    assert_empty selection.fetch(:rows)
    refute selection.fetch(:required_used)
    assert_match(/missing: Rspec test for gem/, selection.fetch(:message))
  end

  def test_hosted_request_keeps_other_current_head_checks
    required_rows = [ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS")]
    replay_check = ci_check("rspack-vite-dx-check", bucket: "fail", state: "FAILURE")
    hosted_rows = [
      ci_check("build", bucket: "pass", state: "SUCCESS").merge("workflow" => "Lint JS and Ruby")
    ]

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: required_rows + [replay_check],
      hosted_ci_requested: true,
      hosted_rows:,
      expected_hosted_workflows: ["Lint JS and Ruby"]
    )

    assert_includes selection.fetch(:rows), replay_check
    readiness = PrMergeLedger.ci_readiness_from_check_rows(
      123,
      required_used: selection.fetch(:required_used),
      rows: selection.fetch(:rows),
      message: selection.fetch(:message)
    )
    assert_equal "NOT_READY", readiness.fetch("verdict")
  end

  def test_hosted_request_deduplicates_the_same_check_from_full_and_hosted_rows
    full_check = ci_check(
      "build",
      bucket: "pending",
      state: "IN_PROGRESS",
      link: "https://github.com/shakacode/react_on_rails/actions/runs/1/job/2"
    )
    hosted_check = ci_check(
      "build",
      bucket: "pass",
      state: "SUCCESS",
      link: "https://github.com/shakacode/react_on_rails/actions/runs/1/job/2"
    ).merge("workflow" => "Lint JS and Ruby")

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: [full_check],
      hosted_ci_requested: true,
      hosted_rows: [hosted_check],
      expected_hosted_workflows: ["Lint JS and Ruby"]
    )

    assert_equal [hosted_check], selection.fetch(:rows)
  end

  def test_hosted_request_keeps_same_named_checks_with_distinct_links
    full_check = ci_check(
      "build",
      bucket: "pass",
      state: "SUCCESS",
      link: "https://github.com/shakacode/react_on_rails/actions/runs/1/job/2"
    )
    hosted_check = ci_check(
      "build",
      bucket: "pass",
      state: "SUCCESS",
      link: "https://github.com/shakacode/react_on_rails/actions/runs/3/job/4"
    ).merge("workflow" => "Lint JS and Ruby")

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: [full_check],
      hosted_ci_requested: true,
      hosted_rows: [hosted_check],
      expected_hosted_workflows: ["Lint JS and Ruby"]
    )

    assert_equal [full_check, hosted_check], selection.fetch(:rows)
  end

  def test_hosted_request_preserves_legitimate_mutually_exclusive_skips
    hosted_rows = [
      ci_check("Lint JS and Ruby / workflow", bucket: "pass", state: "SUCCESS")
        .merge("workflow" => "Lint JS and Ruby"),
      ci_check("build", bucket: "pass", state: "SUCCESS").merge("workflow" => "Lint JS and Ruby"),
      ci_check("docs-format-check", bucket: "skipping", state: "SKIPPED")
        .merge("workflow" => "Lint JS and Ruby")
    ]

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: [],
      hosted_ci_requested: true,
      hosted_rows:,
      expected_hosted_workflows: ["Lint JS and Ruby"]
    )
    readiness = PrMergeLedger.ci_readiness_from_check_rows(
      123,
      required_used: selection.fetch(:required_used),
      rows: selection.fetch(:rows),
      message: selection.fetch(:message)
    )

    skipped_check = selection.fetch(:rows).find { |row| row["state"] == "SKIPPED" }
    assert_equal "skipping", skipped_check.fetch("bucket")
    assert_equal "READY", readiness.fetch("verdict")
  end

  def test_hosted_ci_accepts_command_dispatch_and_labeled_synchronize_runs
    assert PrMergeLedger.hosted_ci_run_event?("workflow_dispatch", allow_pull_request: true)
    assert PrMergeLedger.hosted_ci_run_event?("pull_request", allow_pull_request: true)
    refute PrMergeLedger.hosted_ci_run_event?("push", allow_pull_request: true)
  end

  def test_dependabot_hosted_ci_requires_trusted_dispatch
    assert PrMergeLedger.hosted_ci_run_event?("workflow_dispatch", allow_pull_request: false)
    refute PrMergeLedger.hosted_ci_run_event?("pull_request", allow_pull_request: false)
  end
end

class PrMergeLedgerHostedCiSafetyTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_hosted_request_rejects_a_workflow_with_only_skipped_rows
    hosted_rows = [
      ci_check("Generator tests / workflow", bucket: "skipping", state: "SKIPPED")
        .merge("workflow" => "Generator tests"),
      ci_check("matrix.job_name", bucket: "skipping", state: "SKIPPED")
        .merge("workflow" => "Generator tests")
    ]

    selection = PrMergeLedger.select_ci_readiness_rows(
      full_rows: [],
      hosted_ci_requested: true,
      hosted_rows:,
      expected_hosted_workflows: ["Generator tests"]
    )

    assert_empty selection.fetch(:rows)
    assert_match(/no executed rows: Generator tests/, selection.fetch(:message))
  end

  def test_fork_and_dependabot_prs_require_trusted_dispatch
    assert PrMergeLedger.allow_pull_request_hosted_ci?(
      "author" => { "login" => "maintainer" },
      "isCrossRepository" => false
    )
    fork_allows_pull_request = PrMergeLedger.allow_pull_request_hosted_ci?(
      "author" => { "login" => "external-contributor" },
      "isCrossRepository" => true
    )
    refute fork_allows_pull_request
    refute PrMergeLedger.hosted_ci_run_event?("pull_request", allow_pull_request: fork_allows_pull_request)
    assert PrMergeLedger.hosted_ci_run_event?("workflow_dispatch", allow_pull_request: fork_allows_pull_request)
    %w[dependabot dependabot[bot]].each do |login|
      refute PrMergeLedger.allow_pull_request_hosted_ci?(
        "author" => { "login" => login },
        "isCrossRepository" => false
      )
    end
    assert PrMergeLedger.allow_pull_request_hosted_ci?(
      "author" => { "login" => "dependabot-preview" },
      "isCrossRepository" => false
    )
    refute PrMergeLedger.allow_pull_request_hosted_ci?(
      "author" => { "login" => "maintainer" }
    )
  end
end

module PrMergeLedgerHostedCiRequestFixtures
  private

  def hosted_label_event(label, actor:, at:, type: "LabeledEvent")
    {
      "__typename" => type,
      "createdAt" => at,
      "actor" => { "login" => actor },
      "label" => { "name" => label }
    }
  end

  def hosted_command_comment(command, at:)
    {
      "body" => command,
      "createdAt" => at,
      "authorAssociation" => "MEMBER"
    }
  end
end

class PrMergeLedgerHostedCiRequestTrustTest < Minitest::Test
  include PrMergeLedgerHostedCiRequestFixtures

  def test_hosted_request_time_uses_trusted_command_before_bot_added_labels
    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: %w[ready-for-hosted-ci force-full-hosted-ci],
      label_events: [
        hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:02:00Z"),
        hosted_label_event("force-full-hosted-ci", actor: "github-actions", at: "2026-07-13T10:02:00Z")
      ],
      comments: [hosted_command_comment("+ci-force-full", at: "2026-07-13T10:01:00Z")],
      head_committed_at: "2026-07-13T10:00:00Z",
      trusted_label_actors: []
    )

    assert_equal Time.iso8601("2026-07-13T10:01:00Z"), threshold
  end

  def test_hosted_request_time_uses_new_head_time_for_persistent_labels
    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: ["ready-for-hosted-ci"],
      label_events: [
        hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T09:00:00Z")
      ],
      comments: [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T08:59:00Z")],
      head_committed_at: "2026-07-13T10:00:00Z",
      trusted_label_actors: []
    )

    assert_equal Time.iso8601("2026-07-13T10:00:00Z"), threshold
  end

  def test_hosted_request_time_accepts_a_trusted_direct_label_actor
    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: ["ready-for-hosted-ci"],
      label_events: [
        hosted_label_event("ready-for-hosted-ci", actor: "maintainer", at: "2026-07-13T10:02:00Z")
      ],
      comments: [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:03:00Z")],
      head_committed_at: "2026-07-13T10:00:00Z",
      trusted_label_actors: ["maintainer"]
    )

    assert_equal Time.iso8601("2026-07-13T10:02:00Z"), threshold
  end

  def test_github_actions_label_rejects_a_command_after_the_label
    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events: [
          hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:01:00Z")
        ],
        comments: [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:02:00Z")],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: []
      )
    end

    assert_match(/no trusted hosted CI start command lineage/, error.message)
  end

  def test_hosted_request_time_rejects_untrusted_direct_label_actor
    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events: [
          hosted_label_event("ready-for-hosted-ci", actor: "outsider", at: "2026-07-13T10:02:00Z")
        ],
        comments: [],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: []
      )
    end

    assert_match(/untrusted hosted CI label actor outsider/, error.message)
  end

  def test_force_full_request_requires_force_full_command_lineage
    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: %w[ready-for-hosted-ci force-full-hosted-ci],
        label_events: [
          hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:02:00Z"),
          hosted_label_event("force-full-hosted-ci", actor: "github-actions", at: "2026-07-13T10:02:00Z")
        ],
        comments: [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:01:00Z")],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: []
      )
    end

    assert_match(/trusted \+ci-force-full command/, error.message)
  end

  def test_bot_relabel_requires_a_new_command_in_the_current_label_epoch
    label_events = [
      hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:01:00Z"),
      hosted_label_event(
        "ready-for-hosted-ci",
        actor: "maintainer",
        at: "2026-07-13T10:03:00Z",
        type: "UnlabeledEvent"
      ),
      hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:05:00Z")
    ]
    old_command = hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:00:00Z")

    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events:,
        comments: [old_command],
        head_committed_at: "2026-07-13T09:59:00Z",
        trusted_label_actors: []
      )
    end
    assert_match(/no trusted hosted CI start command lineage/, error.message)

    boundary_command = hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:03:00Z")
    boundary_error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events:,
        comments: [boundary_command],
        head_committed_at: "2026-07-13T09:59:00Z",
        trusted_label_actors: []
      )
    end
    assert_match(/no trusted hosted CI start command lineage/, boundary_error.message)

    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: ["ready-for-hosted-ci"],
      label_events:,
      comments: [old_command, hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:04:00Z")],
      head_committed_at: "2026-07-13T09:59:00Z",
      trusted_label_actors: []
    )
    assert_equal Time.iso8601("2026-07-13T10:04:00Z"), threshold
  end

  def test_same_timestamp_label_churn_fails_closed
    label_events = [
      hosted_label_event("ready-for-hosted-ci", actor: "maintainer", at: "2026-07-13T10:03:00Z"),
      hosted_label_event(
        "ready-for-hosted-ci",
        actor: "maintainer",
        at: "2026-07-13T10:03:00Z",
        type: "UnlabeledEvent"
      ),
      hosted_label_event("ready-for-hosted-ci", actor: "github-actions", at: "2026-07-13T10:03:00Z")
    ]

    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events:,
        comments: [],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: ["maintainer"]
      )
    end

    assert_match(/ambiguous latest timeline events/, error.message)
  end
end

class PrMergeLedgerDependabotHostedCiRequestTrustTest < Minitest::Test
  include PrMergeLedgerHostedCiRequestFixtures

  def test_prelabel_uses_a_later_trusted_command_and_normal_head_threshold
    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: ["ready-for-hosted-ci"],
      label_events: [
        hosted_label_event("ready-for-hosted-ci", actor: "dependabot", at: "2026-07-13T09:00:00Z")
      ],
      comments: [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:01:00Z")],
      head_committed_at: "2026-07-13T10:02:00Z",
      trusted_label_actors: []
    )

    assert_equal Time.iso8601("2026-07-13T10:02:00Z"), threshold
  end

  def test_prelabel_requires_a_later_trusted_command
    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events: [
          hosted_label_event("ready-for-hosted-ci", actor: "dependabot[bot]", at: "2026-07-13T09:00:00Z")
        ],
        comments: [],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: []
      )
    end

    assert_match(/no later trusted hosted CI start command lineage/, error.message)
  end

  def test_relabel_rejects_a_command_before_the_active_dependabot_label
    label_events = [
      hosted_label_event("ready-for-hosted-ci", actor: "dependabot", at: "2026-07-13T09:00:00Z"),
      hosted_label_event(
        "ready-for-hosted-ci",
        actor: "maintainer",
        at: "2026-07-13T10:03:00Z",
        type: "UnlabeledEvent"
      ),
      hosted_label_event("ready-for-hosted-ci", actor: "dependabot", at: "2026-07-13T10:05:00Z")
    ]
    stale_command = hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:04:00Z")

    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.hosted_ci_request_not_before(
        active_labels: ["ready-for-hosted-ci"],
        label_events:,
        comments: [stale_command],
        head_committed_at: "2026-07-13T10:00:00Z",
        trusted_label_actors: []
      )
    end

    assert_match(/no later trusted hosted CI start command lineage/, error.message)
  end

  def test_prelabel_accepts_force_full_command_with_bot_added_force_full_label
    threshold = PrMergeLedger.hosted_ci_request_not_before(
      active_labels: %w[ready-for-hosted-ci force-full-hosted-ci],
      label_events: [
        hosted_label_event("ready-for-hosted-ci", actor: "dependabot", at: "2026-07-13T09:00:00Z"),
        hosted_label_event("force-full-hosted-ci", actor: "github-actions", at: "2026-07-13T10:02:00Z")
      ],
      comments: [hosted_command_comment("+ci-force-full", at: "2026-07-13T10:01:00Z")],
      head_committed_at: "2026-07-13T10:00:00Z",
      trusted_label_actors: []
    )

    assert_equal Time.iso8601("2026-07-13T10:01:00Z"), threshold
  end
end

class PrMergeLedgerHostedCiSuiteFreshnessTest < Minitest::Test
  def test_hosted_suite_selection_rejects_pre_request_evidence
    stale_suite = hosted_suite("Lint JS and Ruby", at: "2026-07-13T10:00:00Z")
    boundary_suite = hosted_suite("Lint JS and Ruby", at: "2026-07-13T10:01:00Z")
    fresh_suite = hosted_suite("Lint JS and Ruby", at: "2026-07-13T10:02:00Z")

    assert_empty PrMergeLedger.select_hosted_ci_suites(
      [stale_suite, boundary_suite],
      expected_workflows: ["Lint JS and Ruby"],
      allow_pull_request: true,
      not_before: Time.iso8601("2026-07-13T10:01:00Z")
    )
    assert_equal [fresh_suite], PrMergeLedger.select_hosted_ci_suites(
      [stale_suite, fresh_suite],
      expected_workflows: ["Lint JS and Ruby"],
      allow_pull_request: true,
      not_before: Time.iso8601("2026-07-13T10:01:00Z")
    )
  end

  def test_hosted_suite_selection_fails_closed_on_equal_latest_timestamps
    passing_suite = hosted_suite("Lint JS and Ruby", at: "2026-07-13T10:02:00Z").merge("conclusion" => "SUCCESS")
    failing_suite = hosted_suite("Lint JS and Ruby", at: "2026-07-13T10:02:00Z").merge("conclusion" => "FAILURE")

    error = assert_raises(PrMergeLedger::Error) do
      PrMergeLedger.select_hosted_ci_suites(
        [passing_suite, failing_suite],
        expected_workflows: ["Lint JS and Ruby"],
        allow_pull_request: true,
        not_before: Time.iso8601("2026-07-13T10:01:00Z")
      )
    end

    assert_match(/ambiguous latest workflow runs for Lint JS and Ruby/, error.message)
  end

  private

  def hosted_suite(workflow, at:)
    {
      "workflowRun" => {
        "event" => "pull_request",
        "createdAt" => at,
        "workflow" => { "name" => workflow }
      }
    }
  end
end

class PrMergeLedgerGitHubCollectorTest < Minitest::Test
  include PrMergeLedgerHostedCiRequestFixtures

  def test_fetch_labels_uses_the_paginated_connection
    collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails")
    captured = nil
    collector.define_singleton_method(:fetch_paginated_connection) do |pr_number, query, connection_name|
      captured = [pr_number, query, connection_name]
      [{ "name" => "ready-for-hosted-ci" }]
    end

    labels = collector.send(:fetch_labels, 4626)

    assert_equal [{ "name" => "ready-for-hosted-ci" }], labels
    assert_equal 4626, captured.fetch(0)
    assert_includes captured.fetch(1), "labels(first:100, after:$endCursor)"
    assert_equal "labels", captured.fetch(2)
  end

  def test_dependabot_label_actor_uses_command_lineage_without_permission_lookup
    metadata = {
      "labels" => { "nodes" => [{ "name" => "ready-for-hosted-ci" }] },
      "headRefOid" => "abc123",
      "commits" => {
        "nodes" => [{ "commit" => { "oid" => "abc123", "committedDate" => "2026-07-13T10:00:00Z" } }]
      }
    }
    comments = [hosted_command_comment("+ci-run-hosted", at: "2026-07-13T10:01:00Z")]

    %w[dependabot dependabot[bot]].each do |actor|
      collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails")
      dependabot_label_event = hosted_label_event(
        "ready-for-hosted-ci",
        actor:,
        at: "2026-07-13T09:00:00Z"
      )
      collector.define_singleton_method(:fetch_paginated_connection) do |_pr_number, _query, connection_name|
        raise "unexpected connection #{connection_name}" unless connection_name == "timelineItems"

        [dependabot_label_event]
      end
      collector.define_singleton_method(:trusted_hosted_ci_label_actor?) do |permission_actor|
        raise "unexpected permission lookup for #{permission_actor}"
      end

      threshold = collector.send(:hosted_ci_request_not_before, metadata, 4626, comments)

      assert_equal Time.iso8601("2026-07-13T10:01:00Z"), threshold
    end
  end

  def test_dependabot_graphql_and_rest_logins_exclude_pro_workflows
    collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails")
    expected = PrMergeLedger::HOSTED_CI_WORKFLOW_NAMES - PrMergeLedger::DEPENDABOT_HOSTED_CI_EXCLUSIONS

    %w[dependabot dependabot[bot]].each do |login|
      actual = collector.send(:expected_hosted_workflows, "author" => { "login" => login })
      assert_equal expected, actual
    end
    preview_workflows = collector.send(
      :expected_hosted_workflows,
      "author" => { "login" => "dependabot-preview" }
    )
    assert_equal PrMergeLedger::HOSTED_CI_WORKFLOW_NAMES, preview_workflows
  end
end

class PrMergeLedgerTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_ready_ci_allows_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "READY",
          checks: [
            ci_check("Lint JS and Ruby / build", bucket: "pass", state: "SUCCESS")
          ]
        )
      )
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty data.fetch("violations")
    assert_equal "READY", ledger(data).fetch("ci_readiness").fetch("verdict")
  end

  def test_failed_ci_blocks_strict_closeout_with_check_name
    output, status = run_fixture(
      fixture(
        number: 4444,
        ci_readiness: ci_readiness(
          number: 4444,
          verdict: "NOT_READY",
          checks: [
            ci_check(
              "JS unit tests for Renderer package / build (22)",
              bucket: "fail",
              state: "FAILURE",
              link: "https://github.com/shakacode/react_on_rails/actions/runs/28660148440/job/84998580503"
            )
          ]
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    refute data.fetch("complete_allowed")
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal 4444, ci_readiness.fetch("pr")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    failing_check_names = ci_readiness.fetch("failing").map { |check| check.fetch("name") }
    assert_equal ["JS unit tests for Renderer package / build (22)"], failing_check_names
    assert_equal ["ci_check_failed"], violation_codes(data)
  end

  def test_check_rows_override_inconsistent_ready_ci_payload
    checks = [ci_check("lint", bucket: "fail", state: "FAILURE")]
    readiness = ci_readiness(verdict: "READY", checks:)
    readiness["failing"] = []
    readiness["pending"] = []

    output, status = run_fixture(fixture(ci_readiness: readiness))

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    failing_check_names = ci_readiness.fetch("failing").map { |check| check.fetch("name") }
    assert_equal ["lint"], failing_check_names
    assert_equal ["ci_check_failed"], violation_codes(data)
  end

  def test_pending_ci_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "NOT_READY",
          checks: [
            ci_check("Integration Tests / build", bucket: "pending", state: "PENDING")
          ]
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_check_pending"], violation_codes(data)
  end

  def test_not_ready_ci_without_check_details_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          verdict: "NOT_READY",
          checks: []
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_not_ready"], violation_codes(data)
    message = ledger(data).fetch("violations").fetch(0).fetch("message")
    assert_match(/NOT_READY/, message)
  end

  def test_unknown_ci_blocks_strict_closeout
    output, status = run_fixture(
      fixture(
        ci_readiness: ci_readiness(
          status: "UNKNOWN",
          verdict: "UNKNOWN",
          checks: [],
          message: "no active current-head check rows were returned"
        )
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["ci_readiness.verdict"], unknown_field_names(data)
    assert_equal ["unknown_ci_readiness"], violation_codes(data)
  end

  def test_cancel_only_ci_without_explicit_verdict_is_unknown
    output, status = run_fixture(
      fixture(
        ci_readiness: {
          "pr" => 123,
          "status" => "known",
          "required_used" => true,
          "checks" => [
            ci_check("required-pr-gate", bucket: "cancel", state: "CANCELLED")
          ]
        }
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "UNKNOWN", ci_readiness.fetch("verdict")
    assert_equal ["ci_readiness.verdict"], unknown_field_names(data)
    assert_equal ["unknown_ci_readiness"], violation_codes(data)
  end

  def test_cancelled_row_with_passing_check_is_not_ready
    output, status = run_fixture(
      fixture(
        ci_readiness: {
          "pr" => 123,
          "status" => "known",
          "required_used" => true,
          "checks" => [
            ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS"),
            ci_check("rspec-package-tests", bucket: "cancel", state: "CANCELLED")
          ]
        }
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    ci_readiness = ledger(data).fetch("ci_readiness")
    assert_equal "NOT_READY", ci_readiness.fetch("verdict")
    pending_check_names = ci_readiness.fetch("pending").map { |check| check.fetch("name") }
    assert_equal ["rspec-package-tests"], pending_check_names
    assert_equal ["ci_check_cancelled"], violation_codes(data)
  end
end

require_relative "pr_merge_ledger_closing_keyword_test"
