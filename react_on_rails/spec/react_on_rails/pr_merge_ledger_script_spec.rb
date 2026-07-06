# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "script/pr-merge-ledger" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "script/pr-merge-ledger") }
  let(:fixture_path) do
    File.join(repo_root, "react_on_rails/spec/react_on_rails/fixtures/pr_merge_ledger/pr_3613.json")
  end

  def with_fake_gh(script_body)
    Dir.mktmpdir("pr-merge-ledger-gh") do |bin_dir|
      gh_path = File.join(bin_dir, "gh")
      File.write(gh_path, fake_gh_script_with_ready_checks(script_body))
      File.chmod(0o755, gh_path)

      yield({ "PATH" => "#{bin_dir}:#{ENV.fetch('PATH', '')}" })
    end
  end

  def with_raw_fake_gh(script_body)
    Dir.mktmpdir("pr-merge-ledger-gh") do |bin_dir|
      gh_path = File.join(bin_dir, "gh")
      File.write(gh_path, script_body)
      File.chmod(0o755, gh_path)

      yield({ "PATH" => "#{bin_dir}:#{ENV.fetch('PATH', '')}" }, bin_dir)
    end
  end

  def fake_gh_script_with_ready_checks(script_body)
    <<~SH
      #!/bin/sh
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
        cat <<'JSON'
      [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
        exit 0
      fi

      #{script_body}
    SH
  end

  def fake_gh_script_with_check_rows(
    required_json:,
    full_json:,
    pr_checks_exit_status: 0,
    fail_first_pr_checks: nil,
    pr_checks_stderr: nil,
    pr_checks_sleep_seconds: nil
  )
    <<~SH
      #!/bin/sh
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
        count_file="$(dirname "$0")/pr-check-calls"
        count=0
        if [ -f "$count_file" ]; then
          count=$(cat "$count_file")
        fi
        count=$((count + 1))
        printf '%s\\n' "$count" > "$count_file"

        if [ "$count" -eq 1 ] && [ -n #{fail_first_pr_checks.to_s.inspect} ]; then
          printf '%s\\n' #{fail_first_pr_checks.to_s.inspect} >&2
          exit 1
        fi

        if [ -n #{pr_checks_sleep_seconds.to_s.inspect} ]; then
          sleep #{pr_checks_sleep_seconds.to_s.inspect}
          exit 1
        fi

        required=false
        for arg in "$@"; do
          if [ "$arg" = "--required" ]; then
            required=true
          fi
        done

        if [ "$required" = "true" ]; then
          cat <<'JSON'
      #{required_json}
      JSON
        else
          cat <<'JSON'
      #{full_json}
      JSON
        fi
        if [ -n #{pr_checks_stderr.to_s.inspect} ]; then
          printf '%s\\n' #{pr_checks_stderr.to_s.inspect} >&2
        fi
        exit #{pr_checks_exit_status}
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH
  end

  def write_fixture(file, fixture, binary: false)
    fixture = with_default_fixture_review_reply_author_associations(fixture)
    fixture = fixture.merge(default_ci_readiness) if fixture_needs_default_ci_readiness?(fixture)
    json = JSON.generate(fixture)
    file.write(binary ? json.b : json)
  end

  def with_default_fixture_review_reply_author_associations(fixture)
    return fixture unless fixture.is_a?(Hash)

    fixture.fetch("review_threads", []).each do |thread|
      Array(thread["comments"]).each do |comment|
        next unless comment.is_a?(Hash)
        next unless comment.key?("replyTo")
        next if comment.key?("authorAssociation")

        comment["authorAssociation"] = "MEMBER"
      end
    end
    fixture
  end

  def fixture_needs_default_ci_readiness?(fixture)
    fixture.is_a?(Hash) &&
      fixture["pull_request"].is_a?(Hash) &&
      !fixture.key?("ci_readiness") &&
      !fixture.key?("checks")
  end

  def default_ci_readiness
    {
      "ci_readiness" => {
        "status" => "known",
        "verdict" => "READY",
        "required_used" => true,
        "failing" => [],
        "pending" => [],
        "checks" => []
      }
    }
  end

  it "reports the known #3613 CHANGES_REQUESTED merge-ledger violation" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "--fixture",
      fixture_path,
      "--changelog-classification",
      "not_user_visible",
      "--strict",
      chdir: repo_root
    )

    expect(status).not_to be_success
    expect(stderr).to include("ledger violations")

    report = JSON.parse(stdout)
    pr_ledger = report.fetch("pull_requests").first
    violation_codes = report.fetch("violations").map { |violation| violation.fetch("code") }

    expect(report.fetch("schema_version")).to eq("pr-merge-ledger/v1")
    expect(report.dig("source", "path")).to eq(
      "react_on_rails/spec/react_on_rails/fixtures/pr_merge_ledger/pr_3613.json"
    )
    expect(report.fetch("complete_allowed")).to be(false)
    expect(pr_ledger.dig("pr", "number")).to eq(3613)
    expect(pr_ledger.dig("review_objects", "review_decision")).to eq("CHANGES_REQUESTED")
    expect(pr_ledger.dig("review_objects", "changes_requested")).to be_empty
    expect(pr_ledger.dig("review_objects", "all_changes_requested").first).to include(
      "reviewer" => "coderabbitai",
      "head_sha" => "d4d94358873321664b1e3a8c2a297f793a8ae3ed"
    )
    expect(pr_ledger.dig("review_objects", "latest_by_reviewer").first).to include(
      "reviewer" => "coderabbitai",
      "state" => "COMMENTED",
      "head_sha" => "62ecd5760e3466726a3be1ed77b0071665c5cf2d",
      "current_head" => true
    )
    expect(pr_ledger.dig("unresolved_current_head_review_threads", "count")).to eq(1)
    expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
      "severity" => "P2",
      "disposition" => "UNKNOWN"
    )
    expect(pr_ledger.dig("changelog_classification", "classification")).to eq("not_user_visible")
    expect(pr_ledger.dig("lockfile_diff", "has_lockfile_diff")).to be(false)
    expect(violation_codes).to include(
      "review_decision_changes_requested",
      "unresolved_current_head_review_thread",
      "unknown_priority_finding_disposition"
    )
    expect(violation_codes).not_to include("changes_requested_review_object")
  end

  it "blocks missing review decisions in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-unknown", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("unknown_fields").first).to include(
        "field" => "pr.review_decision",
        "message" => "GitHub reviewDecision is UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_review_decision"
      )
    end
  end

  it "blocks missing review decisions and current changes-requested reviews in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-1",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-19T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-1",
          "body" => "Please fix this before merge."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-unknown-review-decision-change-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_review_decision",
        "changes_requested_review_object"
      )
    end
  end

  it "treats null review decisions as not required when no review blockers remain" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => nil
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-null-review-decision", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "review_decision")).to eq("NOT_REQUIRED")
      expect(report.fetch("complete_allowed")).to be(true)
      expect(report.fetch("unknown_fields")).to be_empty
      expect(report.fetch("violations")).to be_empty
    end
  end

  it "reports UNKNOWN lockfile status when file data is unavailable" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-missing-files", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "lockfile_diff")).to include(
        "status" => "UNKNOWN",
        "has_lockfile_diff" => "UNKNOWN",
        "files" => []
      )
      expect(report.fetch("unknown_fields").first).to include(
        "field" => "lockfile_diff.has_lockfile_diff",
        "message" => "lockfile diff flag is UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_lockfile_diff"
      )
    end
  end

  it "treats blank review decisions as not required when no review blockers remain" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => ""
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-blank-review-decision", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "review_decision")).to eq("NOT_REQUIRED")
      expect(report.fetch("complete_allowed")).to be(true)
      expect(report.fetch("violations")).to be_empty
    end
  end

  it "blocks current changes-requested reviews when aggregate review decision is not required" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => nil
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-1",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-19T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-1",
          "body" => "Please fix this before merge."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-null-review-decision-change-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "review_decision")).to eq("NOT_REQUIRED")
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "changes_requested_review_object"
      )
    end
  end

  it "blocks current changes-requested reviews when aggregate review decision is blank" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => ""
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-1",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-19T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-1",
          "body" => "Please fix this before merge."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-blank-review-decision-change-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "review_decision")).to eq("NOT_REQUIRED")
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "changes_requested_review_object"
      )
    end
  end

  it "blocks REVIEW_REQUIRED review decisions in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "abc123",
        "reviewDecision" => "REVIEW_REQUIRED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-review-required", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "review_decision_review_required"
      )
    end
  end

  it "normalizes unsupported review decisions to UNKNOWN so output stays schema-valid" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 1,
        "headRefOid" => "abc123",
        "reviewDecision" => "REVIEW_BYPASSED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-unsupported-review-decision", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "review_decision")).to eq("UNKNOWN")
      expect(report.dig("pull_requests", 0, "pr")).not_to have_key("review_decision_raw")
      expect(report.fetch("unknown_fields").first).to include(
        "field" => "pr.review_decision",
        "message" => "GitHub reviewDecision is unsupported: REVIEW_BYPASSED"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_review_decision"
      )
    end
  end

  it "exits successfully outside strict mode while still reporting violations" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "abc123",
        "reviewDecision" => "REVIEW_REQUIRED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-non-strict-violations", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "review_decision_review_required"
      )
    end
  end

  it "blocks explicit missing changelog classifications in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 3,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-missing-changelog", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "changelog_missing",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "changelog_missing"
      )
    end
  end

  it "allows explicit non-blocking changelog classifications in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    %w[changelog_present deferred_to_update_changelog].each do |classification|
      Tempfile.create(["pr-merge-ledger-#{classification}", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          classification,
          "--strict",
          chdir: repo_root
        )

        expect(status).to be_success, stderr

        report = JSON.parse(stdout)
        pr_ledger = report.fetch("pull_requests").first
        expect(report.fetch("complete_allowed")).to be(true)
        expect(pr_ledger.dig("changelog_classification", "classification")).to eq(classification)
        expect(report.fetch("violations")).to be_empty
      end
    end
  end

  it "rejects explicit UNKNOWN changelog classification" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 41,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-unknown-changelog", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "UNKNOWN",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("invalid argument: --changelog-classification UNKNOWN")
    end
  end

  it "allows a clean approved PR in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-clean", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(true)
      expect(report.fetch("unknown_fields")).to be_empty
      expect(report.fetch("violations")).to be_empty
    end
  end

  it "blocks draft PRs in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "isDraft" => true,
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-draft", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include("draft_pr")
    end
  end

  it "blocks closed unmerged PRs in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "state" => "CLOSED",
        "mergedAt" => nil,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-closed-unmerged", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "closed_unmerged_pr"
      )
    end
  end

  it "blocks missing head SHA in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 6,
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-missing-head-sha", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "head_sha")).to eq("UNKNOWN")
      expect(report.fetch("unknown_fields").first).to include(
        "field" => "pr.head_sha",
        "message" => "GitHub headRefOid is UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include("unknown_head_sha")
    end
  end

  it "prints a clean error when fixtures are missing pull request data" do
    fixture = {
      "repository" => "shakacode/react_on_rails"
    }

    Tempfile.create(["pr-merge-ledger-missing-pull-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pr-merge-ledger: fixture is missing pull_request")
      expect(stderr).not_to include("from ")
    end
  end

  it "prints a clean error when fixture root data is not an object" do
    Tempfile.create(["pr-merge-ledger-non-object-fixture", ".json"]) do |file|
      file.write(JSON.generate([]))
      file.flush

      stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pr-merge-ledger: fixture must be a JSON object")
      expect(stderr).not_to include("from ")
    end
  end

  it "prints a clean error when fixture pull request data is malformed" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => nil
    }

    Tempfile.create(["pr-merge-ledger-malformed-pull-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pr-merge-ledger:")
      expect(stderr).not_to include("from ")
    end
  end

  it "surfaces unexpected fixture shape errors with a backtrace" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => "not-a-hash"
    }

    Tempfile.create(["pr-merge-ledger-programming-error", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

      expect(status.exitstatus).not_to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("undefined method")
      expect(stderr).to include("script/pr-merge-ledger")
    end
  end

  it "allows superseded change-request reviews after a newer review from the same reviewer" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "old-review",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "old" },
          "url" => "https://example.com/old",
          "body" => "Old requested change."
        },
        {
          "id" => "new-review",
          "state" => "APPROVED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/new",
          "body" => "Approved."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-superseded", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("review_objects", "changes_requested")).to be_empty
      expect(pr_ledger.dig("review_objects", "all_changes_requested").first).to include(
        "id" => "old-review",
        "current_head" => false
      )
    end
  end

  it "blocks current-head change-request reviews even when the reviewer comments later" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "requested-changes",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/requested-changes",
          "body" => "Please fix this."
        },
        {
          "id" => "later-comment",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/later-comment",
          "body" => "Follow-up comment."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-current-change-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      violation_codes = report.fetch("violations").map { |violation| violation.fetch("code") }
      expect(pr_ledger.dig("review_objects", "latest_by_reviewer").first).to include(
        "id" => "later-comment",
        "state" => "COMMENTED"
      )
      expect(pr_ledger.dig("review_objects", "changes_requested").first).to include(
        "id" => "requested-changes",
        "state" => "CHANGES_REQUESTED",
        "current_head" => true
      )
      expect(violation_codes).to include("changes_requested_review_object")
    end
  end

  it "allows current-head change-request reviews after a newer approval from the same reviewer" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "requested-changes",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/requested-changes",
          "body" => "Please fix this."
        },
        {
          "id" => "later-approval",
          "state" => "APPROVED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/later-approval",
          "body" => "Approved now."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-current-approval", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      violation_codes = report.fetch("violations").map { |violation| violation.fetch("code") }
      expect(pr_ledger.dig("review_objects", "latest_by_reviewer").first).to include(
        "id" => "later-approval",
        "state" => "APPROVED"
      )
      expect(pr_ledger.dig("review_objects", "changes_requested")).to be_empty
      expect(pr_ledger.dig("review_objects", "all_changes_requested").first).to include(
        "id" => "requested-changes",
        "state" => "CHANGES_REQUESTED",
        "current_head" => true
      )
      expect(violation_codes).not_to include("changes_requested_review_object")
    end
  end

  it "uses API order as the review tie-breaker when timestamps match" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "requested-changes",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/requested-changes",
          "body" => "Please fix this."
        },
        {
          "id" => "same-second-approval",
          "state" => "APPROVED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/same-second-approval",
          "body" => "Approved now."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-current-approval-tie", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      violation_codes = report.fetch("violations").map { |violation| violation.fetch("code") }
      expect(pr_ledger.dig("review_objects", "latest_by_reviewer").first).to include(
        "id" => "same-second-approval",
        "state" => "APPROVED"
      )
      expect(pr_ledger.dig("review_objects", "changes_requested")).to be_empty
      expect(violation_codes).not_to include("changes_requested_review_object")
    end
  end

  it "ignores stale change-request review objects when the PR decision is clear" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "stale-change-request",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "old" },
          "url" => "https://example.com/stale-change-request",
          "body" => "Old requested change."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-stale-change-request", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("review_objects", "changes_requested")).to be_empty
      expect(pr_ledger.dig("review_objects", "all_changes_requested").first).to include(
        "id" => "stale-change-request",
        "current_head" => false
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).not_to include(
        "changes_requested_review_object"
      )
    end
  end

  it "orders latest reviews by parsed timestamps instead of string order" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 2,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "old-review",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "old" },
          "url" => "https://example.com/old",
          "body" => "Old requested change."
        },
        {
          "id" => "new-review",
          "state" => "APPROVED",
          "submittedAt" => "2026-06-01T20:00:00-05:00",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/new",
          "body" => "Approved."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-parsed-timestamp", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      latest_review = report.dig("pull_requests", 0, "review_objects", "latest_by_reviewer", 0)
      expect(latest_review).to include(
        "id" => "new-review",
        "state" => "APPROVED",
        "current_head" => true
      )
      expect(report.dig("pull_requests", 0, "review_objects", "changes_requested")).to be_empty
    end
  end

  it "ignores negative P1/P2 summary text" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "clean-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/clean-review",
          "body" => "No P1/P2 findings."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-negative-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "scans every current-head review body for priority findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "earlier-current-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/earlier-current-review",
          "body" => "[P2] Earlier current-head finding still needs disposition."
        },
        {
          "id" => "later-current-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/later-current-review",
          "body" => "Later current-head review."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-all-current-reviews", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.first).to include(
        "id" => "earlier-current-review",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "does not scan dismissed or pending review bodies for priority findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "dismissed-review",
          "state" => "DISMISSED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/dismissed-review",
          "body" => "[P1] Dismissed review body should not gate closeout."
        },
        {
          "id" => "pending-review",
          "state" => "PENDING",
          "submittedAt" => nil,
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/pending-review",
          "body" => "[P2] Pending review draft should not gate closeout."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-non-gating-review-findings", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(true)
      expect(report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "still scans submitted merge-relevant review bodies for priority findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "commented-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/commented-review",
          "body" => "[P1] Commented review finding still needs disposition."
        },
        {
          "id" => "changes-requested-review",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/changes-requested-review",
          "body" => "[P2] Changes-requested finding still needs disposition."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-gating-review-findings", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("id") }).to eq(
        %w[commented-review changes-requested-review]
      )
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
    end
  end

  it "blocks P0 findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "critical-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/critical-review",
          "body" => "[P0] Critical blocker."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-p0", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(false)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
        "id" => "critical-review",
        "severity" => "P0",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "blocks badge-style priority findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "badge-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/badge-review",
          "body" => "**<sub><sub>![P2 Badge](https://img.shields.io/badge/P2-yellow?style=flat)</sub></sub> " \
                    "Parse badge-style priority findings**"
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-badge-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "badge-review",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks numbered-list priority findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "numbered-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/numbered-review",
          "body" => "1. [P1] First numbered finding.\n2. P2: Second numbered finding."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-numbered-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["1. [P1] First numbered finding.", "2. P2: Second numbered finding."]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks heading-style priority findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "heading-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/heading-review",
          "body" => "### [P1] Cache invalidation is broken\n## P2: Secondary issue remains"
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-heading-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["### [P1] Cache invalidation is broken", "## P2: Secondary issue remains"]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks task-list priority findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "task-list-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/task-list-review",
          "body" => "- [ ] [P1] Task-list finding.\n- [x] P2: Checked task-list finding."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-task-list-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["- [ ] [P1] Task-list finding.", "- [x] P2: Checked task-list finding."]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks slash-combined priority findings from review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "slash-combined-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/slash-combined-review",
          "body" => "P1/P2 findings still need disposition."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-slash-combined-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P1/P2 findings still need disposition.", "P1/P2 findings still need disposition."]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks or-separated priority findings after the first marker is dispositioned" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "or-separated-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/or-separated-review",
          "body" => "P1 issue fixed or P2 still open."
        }
      ],
      "comments" => []
    }
    dispositions = {
      "https://example.com/or-separated-review#L1:1" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-or-separated-finding", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-or-separated-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success, stderr

        report = JSON.parse(stdout)
        findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
        expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
        expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[fixed UNKNOWN])
        expect(stderr).not_to include("unused disposition keys")
      end
    end
  end

  it "keeps same-severity findings from distinct lines in one source" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-two-findings",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-two-findings",
          "body" => "[P1] First finding.\n[P1] Second finding."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-two-findings", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      findings = pr_ledger.dig("priority_finding_dispositions", "findings")
      expect(findings.length).to eq(2)
      expect(findings.map { |finding| finding.fetch("source_line") }).to eq([1, 2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["[P1] First finding.", "[P1] Second finding."]
      )
    end
  end

  it "uses only the first priority marker on one finding line" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-duplicate-severity",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-duplicate-severity",
          "body" => "MUST-FIX [P1]: duplicated severity markers."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-duplicate-severity", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.length).to eq(1)
      expect(findings.first).to include(
        "severity" => "MUST_FIX",
        "text_excerpt" => "MUST-FIX [P1]: duplicated severity markers."
      )
    end
  end

  it "does not treat priority-looking text inside words as extra findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-priority-looking-title",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-priority-looking-title",
          "body" => "[P1] HTTP2 fallback is broken\n[P1] P256 keys fail"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-priority-looking-title", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.length).to eq(2)
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["[P1] HTTP2 fallback is broken", "[P1] P256 keys fail"]
      )
      expect(findings.map { |finding| finding.fetch("marker_index") }).to eq([1, 1])
    end
  end

  it "does not split priority mentions embedded in a finding title" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-cross-priority-title",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-cross-priority-title",
          "body" => "[P2] Fix handling of P1/P2 summaries"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-cross-priority-title", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.length).to eq(1)
      expect(findings.first).to include(
        "severity" => "P2",
        "marker_index" => 1,
        "text_excerpt" => "[P2] Fix handling of P1/P2 summaries"
      )
    end
  end

  it "reports the primary finding marker column for indented list items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-indented-marker",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-indented-marker",
          "body" => "  - **P0**: Critical issue"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-indented-marker", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first
      expect(finding).to include(
        "severity" => "P0",
        "source_column" => 7,
        "marker_index" => 1
      )
    end
  end

  it "ignores findings from outdated review-thread comments" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "outdated-thread",
          "isResolved" => false,
          "isOutdated" => true,
          "comments" => [
            {
              "id" => "outdated-comment",
              "url" => "https://example.com/outdated-comment",
              "body" => "[P1] Finding from a stale diff.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z"
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-outdated-thread-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "blocks non-outdated review threads even when their original review used an older head commit" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "old-head-thread",
          "isResolved" => false,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "old-head-comment",
              "url" => "https://example.com/old-head-comment",
              "body" => "Old-head comment on an unchanged line.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "old" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-old-head-thread", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      thread = report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "threads", 0)
      expect(report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "count")).to eq(1)
      expect(thread).to include(
        "current_head" => true,
        "current_head_evidence" => "conservative_non_outdated"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unresolved_current_head_review_thread"
      )
    end
  end

  it "uses the review-thread comment URL when id fields are missing" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "url-identified-thread",
          "isResolved" => false,
          "isOutdated" => false,
          "comments" => [
            {
              "url" => "https://example.com/url-identified-comment",
              "body" => "Current-head comment with no numeric id.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-url-comment-id", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      comment = report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "threads", 0, "comments", 0)
      expect(comment.fetch("id")).to eq("https://example.com/url-identified-comment")
    end
  end

  it "does not mark commentless threads as current-head threads" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "commentless-thread",
          "isResolved" => false,
          "isOutdated" => false,
          "comments" => []
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-commentless-thread", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "count")).to eq(0)
      expect(report.fetch("violations")).to be_empty
    end
  end

  it "ignores outdated comments inside unresolved current-head review threads when scanning findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "current-thread-with-stale-comment",
          "isResolved" => false,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "stale-comment",
              "url" => "https://example.com/stale-comment",
              "body" => "[P1] Finding from a stale inline comment.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => true,
              "commit" => { "oid" => "old" }
            },
            {
              "id" => "live-comment",
              "url" => "https://example.com/live-comment",
              "body" => "This thread is still live on the unchanged line.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-02T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-stale-thread-comment", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "count")).to eq(1)
      expect(report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")).to be_empty
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).not_to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "scans resolved current-head review threads for priority finding dispositions" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "resolved-current-comment",
              "url" => "https://example.com/resolved-current-comment",
              "body" => "[P1] Finding from a resolved current-head thread.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-resolved-thread-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(pr_ledger.dig("unresolved_current_head_review_threads", "count")).to eq(0)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
        "id" => "resolved-current-comment",
        "severity" => "P1",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "infers fixed dispositions from direct replies in resolved current-head review threads" do
    long_validation_tail = "tail " * 60
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Addressed by current head `current`. Added a regression test. " \
                        "CI is still passing. " \
                        "Validation: pnpm test -- colors.test.ts. " \
                        "#{long_validation_tail}",
              "author" => { "login" => "justin808" },
              "authorAssociation" => "MEMBER",
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-resolved-thread-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      finding = pr_ledger.dig("priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("unresolved_current_head_review_threads", "count")).to eq(0)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "fixed"
      )
      expect(finding.fetch("evidence")).to include(
        "https://example.com/reply-comment",
        "Validation: pnpm test -- colors.test.ts"
      )
      expect(finding.fetch("evidence")).to end_with("...")
      expect(finding.fetch("evidence")).not_to include(long_validation_tail)
    end
  end

  it "does not infer fixed dispositions from untrusted direct replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "external-contributor" },
              "authorAssociation" => "CONTRIBUTOR",
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-untrusted-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "does not infer fixed dispositions from direct replies with missing author associations" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "authorAssociation" => nil,
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-missing-author-association-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "does not infer fixed dispositions from same-author direct replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "reviewer" },
              "authorAssociation" => "MEMBER",
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-same-author-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "infers fixed dispositions from direct replies that report no regressions" do
    [
      "Fixed in current head `current`. No regression observed on Windows. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Addressed by current head `current`. No regressions found in manual testing. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. No more regressions found in manual testing. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Addressed by current head `current`. No other regressions found in manual testing. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. Added regression testing to cover this case. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Addressed by current head `current`. Covered by the regression suite. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. This avoids regressions in the color parsing. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. No functional regressions observed. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. Regression-free per the full suite run. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. Added a test that fails before the fix and passes after. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. Positive fixed replies with before/after regression-test evidence " \
      "remain inferable. Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. CI no longer fails on Windows. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. CI is not failing anymore on Windows. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. CI isn't failing anymore on Windows. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`: nested fixed-style replies no longer apply a fixed disposition. " \
      "Validation: bundle exec rspec pr_merge_ledger_script_spec.rb.",
      "Fixed in current head `current`. It doesn't fail on Windows anymore. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. It won\u2019t fail on Windows anymore. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. This change no longer breaks the Windows build. " \
      "Validation: pnpm test -- colors.test.ts.",
      "Fixed in current head `current`. CI is no longer broken. " \
      "Validation: pnpm test -- colors.test.ts."
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "reply-comment",
                "url" => "https://example.com/reply-comment",
                "body" => reply_body,
                "author" => { "login" => "justin808" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-no-regression-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).to be_success, stderr

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        expect(report.fetch("complete_allowed")).to be(true)
        expect(finding).to include(
          "id" => "finding-comment",
          "severity" => "P2",
          "disposition" => "fixed"
        )
      end
    end
  end

  it "infers fixed dispositions from direct replies that mention separate validation" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in current head `current`. Verified separately in the dummy app. " \
                        "Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-separate-validation-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(true)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "fixed"
      )
    end
  end

  it "does not infer fixed dispositions from ambiguous direct replies" do
    [
      "\nFixed in current head `current`. Does this look right?",
      "Fixed in colors.test.ts. Is that correct?"
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "reply-comment",
                "url" => "https://example.com/reply-comment",
                "body" => reply_body,
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-ambiguous-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, _stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        expect(report.fetch("complete_allowed")).to be(false)
        expect(finding).to include(
          "id" => "finding-comment",
          "severity" => "P2",
          "disposition" => "UNKNOWN"
        )
        expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
          "unknown_priority_finding_disposition"
        )
      end
    end
  end

  it "infers fixed dispositions when later validation text contains question marks" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in current head `current`. Validation: see https://example.com/ci?run=1. " \
                        "Should CI be green now?",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-fixed-reply-question-in-validation", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(true)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "fixed"
      )
      expect(finding.fetch("evidence")).to include("https://example.com/ci?run=1")
    end
  end

  it "infers fixed dispositions when first-sentence links include query params" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Addressed by current head `current`, see https://example.com/diff?w=1 for the diff. " \
                        "Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-fixed-reply-url-query", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(true)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "fixed"
      )
      expect(finding.fetch("evidence")).to include("https://example.com/diff?w=1")
    end
  end

  it "clears inferred fixed dispositions after later ambiguous direct replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "fixed-reply-comment",
              "url" => "https://example.com/fixed-reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "ambiguous-reply-comment",
              "url" => "https://example.com/ambiguous-reply-comment",
              "body" => "Fixed in current head `current`? Can you confirm the lint result?",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:10:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-later-ambiguous-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "does not infer fixed dispositions from contradicted fixed direct replies" do
    [
      "Fixed in current head, but not fixed on Windows.",
      "Fixed in current head `current`. CI is red.",
      "Addressed by abc123, though the build is broken.",
      "Fixed in current head `current`, but this doesn't address Windows.",
      "Fixed in current head `current`, but this doesn\u2019t fix Windows.",
      "Fixed in current head `current`. Tests fail on Windows.",
      "Fixed in current head `current`. The specs are failing."
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "reply-comment",
                "url" => "https://example.com/reply-comment",
                "body" => reply_body,
                "author" => { "login" => "justin808" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-contradicted-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, _stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        expect(report.fetch("complete_allowed")).to be(false)
        expect(finding).to include(
          "id" => "finding-comment",
          "severity" => "P2",
          "disposition" => "UNKNOWN"
        )
        expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
          "unknown_priority_finding_disposition"
        )
      end
    end
  end

  it "uses API order to break tied direct reply timestamps" do
    finding_comment = {
      "id" => "finding-comment",
      "url" => "https://example.com/finding-comment",
      "body" => "[P2] Pin non-Windows for negative TTY color cases.",
      "author" => { "login" => "reviewer" },
      "createdAt" => "2026-06-01T00:00:00Z",
      "outdated" => false,
      "commit" => { "oid" => "current" }
    }
    fixed_reply = {
      "id" => "fixed-reply-comment",
      "url" => "https://example.com/fixed-reply-comment",
      "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
      "author" => { "login" => "justin808" },
      "createdAt" => "2026-06-01T00:05:00Z",
      "outdated" => false,
      "replyTo" => { "id" => "finding-comment" },
      "commit" => { "oid" => "current" }
    }
    regressed_reply = {
      "id" => "regressed-reply-comment",
      "url" => "https://example.com/regressed-reply-comment",
      "body" => "Actually this regressed, please reopen.",
      "author" => { "login" => "reviewer" },
      "createdAt" => "2026-06-01T00:05:00Z",
      "outdated" => false,
      "replyTo" => { "id" => "finding-comment" },
      "commit" => { "oid" => "current" }
    }

    run_fixture = lambda do |reply_comments|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [finding_comment, *reply_comments]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-tied-fixed-replies", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, _stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        [JSON.parse(stdout), status]
      end
    end

    report, status = run_fixture.call([fixed_reply, regressed_reply])
    finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first
    expect(status).not_to be_success
    expect(finding).to include("disposition" => "UNKNOWN")

    report, status = run_fixture.call([regressed_reply, fixed_reply])
    finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first
    expect(status).to be_success
    expect(finding).to include("disposition" => "fixed")
  end

  it "clears inferred fixed dispositions after later contradictory direct replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "fixed-reply-comment",
              "url" => "https://example.com/fixed-reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "regressed-reply-comment",
              "url" => "https://example.com/regressed-reply-comment",
              "body" => "Actually this regressed, please reopen.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:10:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-later-contradicted-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "clears inferred fixed dispositions after later still-failing direct replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "fixed-reply-comment",
              "url" => "https://example.com/fixed-reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "still-failing-reply-comment",
              "url" => "https://example.com/still-failing-reply-comment",
              "body" => "I still see this\nfailing on CI.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:10:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-later-still-failing-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "clears inferred fixed dispositions after later does-not-work direct replies" do
    [
      "This doesn't work on Windows.",
      "This no longer works on Windows.",
      "CI is no longer passing on Windows.",
      "CI isn't passing on Windows.",
      "CI isn\u2019t passing on Windows.",
      "This doesn't pass on Windows.",
      "CI does not pass on Windows.",
      "This doesn't address Windows.",
      "This doesn\u2019t fix Windows.",
      "This fails on Windows.",
      "Tests fail on Windows.",
      "The specs are failing.",
      "The fix failed on Windows.",
      "This is broken on Windows.",
      "This breaks Windows.",
      "Actually, I just retested and this repros on Windows.",
      "I can still reproduce this issue.",
      "This issue still occurs on Windows.",
      "This still happens on Windows."
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "fixed-reply-comment",
                "url" => "https://example.com/fixed-reply-comment",
                "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
                "author" => { "login" => "justin808" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "does-not-work-reply-comment",
                "url" => "https://example.com/does-not-work-reply-comment",
                "body" => reply_body,
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:10:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-later-does-not-work-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, _stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        expect(report.fetch("complete_allowed")).to be(false)
        expect(finding).to include(
          "id" => "finding-comment",
          "severity" => "P2",
          "disposition" => "UNKNOWN"
        )
        expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
          "unknown_priority_finding_disposition"
        )
      end
    end
  end

  it "clears inferred fixed dispositions after later nested contradictory replies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "fixed-reply-comment",
              "url" => "https://example.com/fixed-reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "nested-regression-reply-comment",
              "url" => "https://example.com/nested-regression-reply-comment",
              "body" => "Actually this regressed on Windows.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:10:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "fixed-reply-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-later-nested-contradictory-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "does not apply nested fixed replies to root priority findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "follow-up-comment",
              "url" => "https://example.com/follow-up-comment",
              "body" => "Please also check the Linux-only fixture.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "nested-fixed-reply-comment",
              "url" => "https://example.com/nested-fixed-reply-comment",
              "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:10:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "follow-up-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-nested-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "preserves inferred fixed dispositions after later unrelated direct replies" do
    [
      "Thanks, that looks good.",
      "Not a big deal, but fixed it in the latest commit.",
      "By the way, unrelated flaky CI checks are failing on main today, nothing to do with this thread."
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "fixed-reply-comment",
                "url" => "https://example.com/fixed-reply-comment",
                "body" => "Fixed in current head `current`. Validation: pnpm test -- colors.test.ts.",
                "author" => { "login" => "justin808" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "thanks-reply-comment",
                "url" => "https://example.com/thanks-reply-comment",
                "body" => reply_body,
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:10:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-later-unrelated-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).to be_success, stderr

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        expect(report.fetch("complete_allowed")).to be(true)
        expect(finding).to include(
          "id" => "finding-comment",
          "severity" => "P2",
          "disposition" => "fixed"
        )
        expect(finding.fetch("evidence")).to include("https://example.com/fixed-reply-comment")
      end
    end
  end

  it "infers fixed dispositions from non-outdated direct replies on current review threads" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Fixed in old head `old`. Validation: pnpm test -- colors.test.ts.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "old" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-non-outdated-fixed-reply", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(true)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "fixed"
      )
      expect(finding.fetch("evidence")).to include("https://example.com/reply-comment")
    end
  end

  it "does not infer fixed dispositions from follow-up direct replies" do
    [
      "Addressed in a follow-up issue #123.",
      "Addressed by #123.",
      "Fixed by https://github.com/shakacode/react_on_rails/issues/123.",
      "Addressed by tracking issue https://github.com/shakacode/react_on_rails/issues/123.",
      "Addressed by tracking ticket ABC-123.",
      "Addressed by https://github.com/shakacode/react_on_rails/pull/123.",
      "Fixed in part, will follow up separately.",
      "Fixed in general but there is a follow-up needed.",
      "Fixed in a hacky way, might need revisit later on.",
      "Fixed in current head for now.",
      "Addressed by current head temporarily.",
      "Fixed in current head as a stopgap.",
      "Fixed in current head `current`. I believe this should work.",
      "Addressed by current head `current`. Probably fixed now.",
      "Fixed in current head `current`. I haven't tested it yet.",
      "Fixed in current head `current`. I haven't had a chance to test it yet.",
      "Fixed in a bit, will verify shortly.",
      "Fixed in current head `current`. Will verify shortly."
    ].each do |reply_body|
      fixture = {
        "repository" => "shakacode/react_on_rails",
        "pull_request" => {
          "number" => 8,
          "headRefOid" => "current",
          "reviewDecision" => "APPROVED"
        },
        "files" => [],
        "review_threads" => [
          {
            "id" => "resolved-current-thread",
            "isResolved" => true,
            "isOutdated" => false,
            "comments" => [
              {
                "id" => "finding-comment",
                "url" => "https://example.com/finding-comment",
                "body" => "[P2] Pin non-Windows for negative TTY color cases.",
                "author" => { "login" => "reviewer" },
                "createdAt" => "2026-06-01T00:00:00Z",
                "outdated" => false,
                "commit" => { "oid" => "current" }
              },
              {
                "id" => "reply-comment",
                "url" => "https://example.com/reply-comment",
                "body" => reply_body,
                "author" => { "login" => "justin808" },
                "createdAt" => "2026-06-01T00:05:00Z",
                "outdated" => false,
                "replyTo" => { "id" => "finding-comment" },
                "commit" => { "oid" => "current" }
              }
            ]
          }
        ],
        "reviews" => [],
        "comments" => []
      }

      Tempfile.create(["pr-merge-ledger-follow-up-fixed-reply", ".json"]) do |file|
        write_fixture(file, fixture)
        file.flush

        stdout, _stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success

        report = JSON.parse(stdout)
        finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

        aggregate_failures(reply_body) do
          expect(report.fetch("complete_allowed")).to be(false)
          expect(finding).to include(
            "id" => "finding-comment",
            "severity" => "P2",
            "disposition" => "UNKNOWN"
          )
          expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
            "unknown_priority_finding_disposition"
          )
        end
      end
    end
  end

  it "does not infer fixed dispositions from broader deferred reply wording" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "resolved-current-thread",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => [
            {
              "id" => "finding-comment",
              "url" => "https://example.com/finding-comment",
              "body" => "[P2] Pin non-Windows for negative TTY color cases.",
              "author" => { "login" => "reviewer" },
              "createdAt" => "2026-06-01T00:00:00Z",
              "outdated" => false,
              "commit" => { "oid" => "current" }
            },
            {
              "id" => "reply-comment",
              "url" => "https://example.com/reply-comment",
              "body" => "Addressed in PR #123.",
              "author" => { "login" => "justin808" },
              "createdAt" => "2026-06-01T00:05:00Z",
              "outdated" => false,
              "replyTo" => { "id" => "finding-comment" },
              "commit" => { "oid" => "current" }
            }
          ]
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-deferred-fixed-reply-wording", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, _stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings").first

      expect(report.fetch("complete_allowed")).to be(false)
      expect(finding).to include(
        "id" => "finding-comment",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "ignores findings from superseded review bodies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "current",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "old-review",
          "state" => "CHANGES_REQUESTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "old" },
          "url" => "https://example.com/old-review",
          "body" => "[P1] Finding from a superseded review."
        },
        {
          "id" => "new-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-02T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "current" },
          "url" => "https://example.com/new-review",
          "body" => "Follow-up review has no blocking findings."
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-superseded-review-finding", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "ignores leading severity summaries that only describe waived or resolved findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "clean-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/clean-review",
          "body" => "P2 findings were waived in the previous review.\nP1 issue was resolved by the latest commit."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-waived-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "ignores resolved multi-severity summary lines" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "resolved-multi-severity-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/resolved-multi-severity-review",
          "body" => [
            "P1/P2 findings fixed.",
            "P1 and P2 findings fixed.",
            "P1 issues fixed; P2 findings resolved.",
            "P1 issues fixed and P2 findings were waived.",
            "P1 issues fixed or waived."
          ].join("\n")
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-resolved-multi-severity-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "ignores priority summaries that explicitly report no issues or findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "clean-no-issues-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/clean-no-issues-review",
          "body" => [
            "P1: no issues found.",
            "P1/P2: no findings",
            "### P2: no items remaining"
          ].join("\n")
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-no-issues-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(true)
      expect(pr_ledger.dig("priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "blocks severity summaries that say an issue is not resolved" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "open-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/open-review",
          "body" => "[P1] issue not resolved"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-unresolved-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "open-review",
        "severity" => "P1",
        "text_excerpt" => "[P1] issue not resolved",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks severity summaries that say an issue is not fully resolved" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "not-fully-resolved-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/not-fully-resolved-review",
          "body" => "[P1] issue not fully resolved"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-not-fully-resolved-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "not-fully-resolved-review",
        "severity" => "P1",
        "text_excerpt" => "[P1] issue not fully resolved",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks severity summaries when bare none is part of an unresolved claim" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "none-of-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/none-of-review",
          "body" => "[P1] issue: none of the tests pass"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-none-of-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "none-of-review",
        "severity" => "P1",
        "text_excerpt" => "[P1] issue: none of the tests pass",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks severity summaries when none starts a continuing unresolved phrase" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "none-the-less-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/none-the-less-review",
          "body" => "P1: none the less, one issue remains"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-none-the-less-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "none-the-less-review",
        "severity" => "P1",
        "text_excerpt" => "P1: none the less, one issue remains",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "ignores priority summaries that say no items remain open" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "none-remaining-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/none-remaining-review",
          "body" => "P1 findings: none remaining\nP2 issues: none open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-none-remaining-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "blocks severity summaries that say no findings are fixed or resolved" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "none-resolved-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/none-resolved-review",
          "body" => "P1 issues: none fixed yet.\nP2 findings: none resolved."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-none-resolved-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P1 issues: none fixed yet.", "P2 findings: none resolved."]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks mixed severity summary lines that still contain an open higher-priority item" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/mixed-review",
          "body" => "P1 issues: resolved; P0 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "mixed-review",
        "severity" => "P1",
        "text_excerpt" => "P1 issues: resolved; P0 still open",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks comma-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "comma-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/comma-mixed-review",
          "body" => "P1 issues fixed, P2 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-comma-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "comma-mixed-review",
        "severity" => "P1",
        "text_excerpt" => "P1 issues fixed, P2 still open",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "blocks however-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "however-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/however-mixed-review",
          "body" => "P1 issues fixed, however P2 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-however-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P1 issues fixed, however P2 still open", "P1 issues fixed, however P2 still open"]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks with-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "with-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/with-mixed-review",
          "body" => "P1 issues fixed with P2 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-with-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P1 issues fixed with P2 still open", "P1 issues fixed with P2 still open"]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks period-separated resolved summaries with later open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "period-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/period-mixed-review",
          "body" => "P2 findings resolved. Please also fix P1 regression."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-period-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P2 P1])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        [
          "P2 findings resolved. Please also fix P1 regression.",
          "P2 findings resolved. Please also fix P1 regression."
        ]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks whitespace-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "space-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/space-mixed-review",
          "body" => "P2 issues fixed P1 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-space-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P2 P1])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P2 issues fixed P1 still open", "P2 issues fixed P1 still open"]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks conjunction-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "conjunction-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/conjunction-mixed-review",
          "body" => "P1 issues fixed and P2 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-conjunction-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        ["P1 issues fixed and P2 still open", "P1 issues fixed and P2 still open"]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
    end
  end

  it "blocks colon- and dash-separated mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "colon-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/colon-mixed-review",
          "body" => "P1 issues fixed: P2 still open"
        },
        {
          "id" => "dash-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/dash-mixed-review",
          "body" => "P1 issues fixed - P2 still open"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-colon-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
      expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2 P1 P2])
      expect(findings.map { |finding| finding.fetch("text_excerpt") }).to eq(
        [
          "P1 issues fixed: P2 still open",
          "P1 issues fixed: P2 still open",
          "P1 issues fixed - P2 still open",
          "P1 issues fixed - P2 still open"
        ]
      )
      expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN UNKNOWN UNKNOWN])
    end
  end

  it "blocks parenthetical mixed severity summary lines with open priority items" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "parenthetical-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/parenthetical-mixed-review",
          "body" => "P1 issues fixed (P2 still open)"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-parenthetical-mixed-summary", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "parenthetical-mixed-review",
        "severity" => "P1",
        "text_excerpt" => "P1 issues fixed (P2 still open)",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "requires an actual resolution word before suppressing previous-review summaries" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "previous-review-still-applies",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/previous-review-still-applies",
          "body" => "[P1] issue from previous review still applies"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-previous-review-still-applies", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      finding = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "previous-review-still-applies",
        "severity" => "P1",
        "text_excerpt" => "[P1] issue from previous review still applies",
        "disposition" => "UNKNOWN"
      )
    end
  end

  it "ignores resolved first-clause summaries even when later context contains a negation" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "resolved-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/resolved-review",
          "body" => "P1: Main issue fixed (not yet resolved in the beta branch)."
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-resolved-first-clause", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(true)
      expect(report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")).to be_empty
    end
  end

  it "blocks P0/P1/P2/Must-Fix findings from top-level PR comments" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P0] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-top-level-comment", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(false)
      expect(pr_ledger.fetch("issue_comments").first).to include(
        "id" => "comment-1",
        "author" => "reviewer"
      )
      expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
        "id" => "comment-1",
        "severity" => "P0",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_disposition"
      )
    end
  end

  it "keeps full issue comment bodies out of the output ledger" do
    long_body = "A long informational comment that should be excerpted in output. " * 4
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => long_body,
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-issue-comment-body", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      issue_comment = report.dig("pull_requests", 0, "issue_comments", 0)
      expect(issue_comment.fetch("body_excerpt")).to end_with("...")
      expect(issue_comment.fetch("body_excerpt").length).to eq(180)
      expect(issue_comment).not_to have_key("body")
    end
  end

  it "blocks priority finding scans that truncate very large comment bodies" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 5,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "large-comment",
          "url" => "https://example.com/large-comment",
          "body" => (["informational"] * 1_005).join("\n"),
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-large-comment-body", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr
      expect(stderr).to include(
        "pr-merge-ledger: https://example.com/large-comment body has 1005 lines; scanning first 1000"
      )
      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(false)
      expect(pr_ledger.dig("priority_finding_dispositions", "status")).to eq("UNKNOWN")
      expect(pr_ledger.dig("priority_finding_dispositions", "truncated_sources").first).to include(
        "id" => "large-comment",
        "url" => "https://example.com/large-comment",
        "line_count" => 1005,
        "scanned_line_count" => 1000
      )
      expect(pr_ledger.fetch("unknown_fields").first).to include(
        "field" => "priority_finding_dispositions.body_scan",
        "message" => "priority finding source body was truncated before full scan",
        "url" => "https://example.com/large-comment"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_priority_finding_body_scan"
      )
    end
  end

  it "blocks truncated review-thread comment pages in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 6,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "thread-with-more-comments",
          "isResolved" => true,
          "isOutdated" => false,
          "comments" => {
            "nodes" => [],
            "pageInfo" => {
              "hasNextPage" => true,
              "endCursor" => "cursor"
            }
          }
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-truncated-comments", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(report.fetch("complete_allowed")).to be(false)
      expect(pr_ledger.dig("unresolved_current_head_review_threads", "count")).to eq(0)
      expect(pr_ledger.dig("unresolved_current_head_review_threads", "threads").first).to be_nil
      expect(pr_ledger["unknown_fields"].first).to include(
        "field" => "review_threads.comments",
        "message" => "review thread comments were truncated by GitHub pagination"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_review_thread_comments"
      )
    end
  end

  it "does not classify incomplete unresolved threads as current-head thread violations" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 6,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [
        {
          "id" => "incomplete-unresolved-thread",
          "isResolved" => false,
          "isOutdated" => false,
          "comments" => {
            "nodes" => [],
            "pageInfo" => {
              "hasNextPage" => true,
              "endCursor" => "cursor"
            }
          }
        }
      ],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-incomplete-unresolved-thread", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      pr_ledger = report.fetch("pull_requests").first
      expect(pr_ledger.dig("unresolved_current_head_review_threads", "count")).to eq(0)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to contain_exactly(
        "unknown_review_thread_comments"
      )
    end
  end

  it "accepts string finding dispositions" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = { "https://example.com/comment-1" => "fixed" }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).to be_success, stderr

        report = JSON.parse(stdout)
        pr_ledger = report.fetch("pull_requests").first
        expect(report.fetch("complete_allowed")).to be(true)
        expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
          "id" => "comment-1",
          "disposition" => "fixed"
        )
      end
    end
  end

  it "allows line-specific finding dispositions for multi-finding sources" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "review-with-two-findings",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/review-with-two-findings",
          "body" => "[P1] First finding.\n[P2] Second finding."
        }
      ],
      "comments" => []
    }
    dispositions = {
      "https://example.com/review-with-two-findings#L2" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-line-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-line-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success, stderr

        report = JSON.parse(stdout)
        findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
        expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN fixed])
        expect(findings.map { |finding| finding.fetch("source_line") }).to eq([1, 2])
        expect(stderr).not_to include("unused disposition keys")
      end
    end
  end

  it "does not apply source-wide dispositions to multi-line findings" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "multi-line-broad-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/multi-line-broad-review",
          "body" => "[P1] First finding needs follow-up.\n[P2] Second finding still open."
        }
      ],
      "comments" => []
    }
    dispositions = {
      "https://example.com/multi-line-broad-review" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-multi-line-broad-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-multi-line-broad-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success, stderr

        report = JSON.parse(stdout)
        findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
        expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
        expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
        expect(stderr).to include("unused disposition keys: https://example.com/multi-line-broad-review")
      end
    end
  end

  it "requires occurrence-specific dispositions for same-line mixed severities" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "same-line-mixed-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/same-line-mixed-review",
          "body" => "P1 issues fixed; P2 still open"
        }
      ],
      "comments" => []
    }
    dispositions = {
      "https://example.com/same-line-mixed-review#L1:1" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-same-line-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-same-line-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success, stderr

        report = JSON.parse(stdout)
        findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
        expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
        expect(findings.map { |finding| finding.fetch("marker_index") }).to eq([1, 2])
        expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[fixed UNKNOWN])
        expect(stderr).not_to include("unused disposition keys")
      end
    end
  end

  it "does not apply source-wide dispositions to same-line mixed severities" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "same-line-broad-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/same-line-broad-review",
          "body" => "P1 issues fixed; P2 still open"
        }
      ],
      "comments" => []
    }
    dispositions = {
      "https://example.com/same-line-broad-review" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-same-line-broad-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-same-line-broad-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success, stderr

        report = JSON.parse(stdout)
        findings = report.dig("pull_requests", 0, "priority_finding_dispositions", "findings")
        expect(findings.map { |finding| finding.fetch("severity") }).to eq(%w[P1 P2])
        expect(findings.map { |finding| finding.fetch("disposition") }).to eq(%w[UNKNOWN UNKNOWN])
        expect(stderr).to include("unused disposition keys: https://example.com/same-line-broad-review")
      end
    end
  end

  it "blocks unused finding disposition keys in strict mode" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = {
      "https://example.com/comment-1" => "fixed",
      "https://example.com/typo" => "fixed"
    }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).not_to be_success
        expect(stderr).to include("unused disposition keys: https://example.com/typo")

        report = JSON.parse(stdout)
        pr_ledger = report.fetch("pull_requests").first
        expect(report.fetch("complete_allowed")).to be(false)
        expect(pr_ledger.dig("priority_finding_dispositions", "unused_keys")).to eq(
          ["https://example.com/typo"]
        )
        expect(report.fetch("unknown_fields").first).to include(
          "field" => "priority_finding_dispositions.unused_keys",
          "message" => "finding disposition keys did not match any priority finding"
        )
        expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
          "unknown_priority_finding_disposition"
        )
      end
    end
  end

  it "rejects finding disposition files that are not JSON objects" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => []
    }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(["fixed"]))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--finding-dispositions",
          dispositions_file.path,
          chdir: repo_root
        )

        expect(status.exitstatus).to eq(2)
        expect(stdout).to be_empty
        expect(stderr).to include("pr-merge-ledger: --finding-dispositions must contain a JSON object")
        expect(stderr).not_to include("from ")
      end
    end
  end

  it "prints the rejected value for invalid finding dispositions" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = { "comment-1" => "UNKNOWN" }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--finding-dispositions",
          dispositions_file.path,
          chdir: repo_root
        )

        expect(status.exitstatus).to eq(2)
        expect(stdout).to be_empty
        expect(stderr).to include('finding disposition "UNKNOWN" must be one of')
      end
    end
  end

  it "rejects non-string finding disposition evidence" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = {
      "comment-1" => {
        "disposition" => "fixed",
        "evidence" => { "url" => "https://example.com/evidence" }
      }
    }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--finding-dispositions",
          dispositions_file.path,
          chdir: repo_root
        )

        expect(status.exitstatus).to eq(2)
        expect(stdout).to be_empty
        expect(stderr).to include("finding disposition evidence for comment-1 must be a string")
        expect(stderr).not_to include("from ")
      end
    end
  end

  it "rejects null finding dispositions" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 7,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-1",
          "url" => "https://example.com/comment-1",
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = { "comment-1" => nil }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--finding-dispositions",
          dispositions_file.path,
          chdir: repo_root
        )

        expect(status.exitstatus).to eq(2)
        expect(stdout).to be_empty
        expect(stderr).to include("finding disposition for comment-1 cannot be null")
      end
    end
  end

  it "prints a clean error for unreadable fixture files" do
    skip "root can read chmod 000 files" if Process.uid.zero?

    Tempfile.create(["pr-merge-ledger-unreadable", ".json"]) do |file|
      file.write("{}")
      file.flush

      begin
        File.chmod(0, file.path)
        stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

        expect(status.exitstatus).to eq(2)
        expect(stdout).to be_empty
        expect(stderr).to include("pr-merge-ledger:")
        expect(stderr).not_to include("from ")
      ensure
        File.chmod(0o600, file.path)
      end
    end
  end

  it "rejects per-run changelog classification for multi-PR live runs" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "1",
      "2",
      "--repo",
      "shakacode/react_on_rails",
      "--changelog-classification",
      "not_user_visible",
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("--changelog-classification applies to one PR at a time")
  end

  it "rejects malformed live repository names before calling GitHub" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "3996",
      "--repo",
      "bad=owner/react_on_rails",
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include('repo must look like OWNER/REPO: "bad=owner/react_on_rails"')
  end

  it "rejects non-positive PR numbers before calling GitHub" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "--repo",
      "shakacode/react_on_rails",
      "--",
      "-1",
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include('PR number must be a positive integer: "-1"')
  end

  it "rejects fixture mode combined with positional PR arguments" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "3996",
      "--fixture",
      fixture_path,
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include(
      "PR number args (3996) are ignored when --fixture is given; remove them or omit --fixture"
    )
  end

  it "warns about invalid review submittedAt values while sorting latest reviews" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [
        {
          "id" => "bad-timestamp-review",
          "state" => "COMMENTED",
          "submittedAt" => "not-a-time",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/bad-timestamp-review",
          "body" => ""
        },
        {
          "id" => "valid-review",
          "state" => "COMMENTED",
          "submittedAt" => "2026-06-01T00:00:00Z",
          "author" => { "login" => "reviewer" },
          "commit" => { "oid" => "abc123" },
          "url" => "https://example.com/valid-review",
          "body" => ""
        }
      ],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-bad-submitted-at", ".json"]) do |file|
      write_fixture(file, fixture)
      file.flush

      stdout, stderr, status = Open3.capture3(
        script_path,
        "--fixture",
        file.path,
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr
      expect(stderr).to include(
        'pr-merge-ledger: review bad-timestamp-review submitted_at has invalid timestamp "not-a-time"; ' \
        "treating as oldest"
      )

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "review_objects", "latest_by_reviewer", 0)).to include(
        "id" => "valid-review",
        "state" => "COMMENTED"
      )
      expect(report.dig("pull_requests", 0, "review_objects", "changes_requested")).to be_empty
    end
  end

  it "times out repository auto-detection" do
    fake_gh = <<~SH
      #!/bin/sh
      if [ "$1" = "repo" ]; then
        sleep 2
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env.merge("PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS" => "1"),
        script_path,
        "1",
        "--changelog-classification",
        "not_user_visible",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("gh repo view timed out after 1 seconds")
    end
  end

  it "rejects non-integer GitHub API timeout values without a backtrace" do
    stdout, stderr, status = Open3.capture3(
      { "PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS" => "thirty" },
      script_path,
      "1",
      "--repo",
      "shakacode/react_on_rails",
      "--changelog-classification",
      "not_user_visible",
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS must be an integer")
    expect(stderr).not_to include("from ")
  end

  it "rejects non-positive GitHub API timeout values without a backtrace" do
    stdout, stderr, status = Open3.capture3(
      { "PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS" => "0" },
      script_path,
      "1",
      "--repo",
      "shakacode/react_on_rails",
      "--changelog-classification",
      "not_user_visible",
      chdir: repo_root
    )

    expect(status.exitstatus).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS must be a positive integer")
    expect(stderr).not_to include("from ")
  end

  it "records an auto-detected repository in live source output" do
    fake_gh = <<~SH
      #!/bin/sh
      if [ "$1" = "repo" ]; then
        printf '%s\\n' 'shakacode/react_on_rails'
        exit 0
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--changelog-classification",
        "not_user_visible",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("source", "repo")).to eq("shakacode/react_on_rails")
      expect(report.fetch("repository")).to eq("shakacode/react_on_rails")
    end
  end

  it "blocks strict live closeout when full checks include a newer pending required row" do
    fake_gh = <<~SH
      #!/bin/sh
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
        count_file="$(dirname "$0")/pr-check-calls"
        count=0
        if [ -f "$count_file" ]; then
          count=$(cat "$count_file")
        fi
        count=$((count + 1))
        printf '%s\\n' "$count" > "$count_file"

        required=false
        for arg in "$@"; do
          if [ "$arg" = "--required" ]; then
            required=true
          fi
        done

        if [ "$required" = "true" ]; then
          cat <<'JSON'
      [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
        else
          cat <<'JSON'
      [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"},{"name":"required-pr-gate","state":"PENDING","bucket":"pending","link":"https://example.com/check-rerun"}]
      JSON
        fi
        exit 8
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    Dir.mktmpdir("pr-merge-ledger-gh") do |bin_dir|
      gh_path = File.join(bin_dir, "gh")
      File.write(gh_path, fake_gh)
      File.chmod(0o755, gh_path)

      stdout, stderr, status = Open3.capture3(
        { "PATH" => "#{bin_dir}:#{ENV.fetch('PATH', '')}" },
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr
      expect(stderr).to include("ledger violations:")

      report = JSON.parse(stdout)
      ledger = report.fetch("pull_requests").fetch(0)
      expect(ledger.fetch("ci_readiness")).to include(
        "verdict" => "NOT_READY",
        "required_used" => false
      )
      expect(ledger.fetch("ci_readiness").fetch("pending").map { |check| check.fetch("name") }).to eq(
        ["required-pr-gate"]
      )
      expect(ledger.fetch("violations").map { |violation| violation.fetch("code") }).to include("ci_check_pending")
      expect(File.read(File.join(bin_dir, "pr-check-calls")).strip).to eq("2")
    end
  end

  it "allows strict live closeout when full checks include an advisory pending row" do
    fake_gh = fake_gh_script_with_check_rows(
      required_json: <<~JSON,
        [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
      full_json: <<~JSON,
        [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"},{"name":"rspec-package-tests","state":"PENDING","bucket":"pending","link":"https://example.com/advisory"}]
      JSON
      pr_checks_exit_status: 8
    )

    with_raw_fake_gh(fake_gh) do |env, bin_dir|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      ledger = JSON.parse(stdout).fetch("pull_requests").fetch(0)
      expect(ledger.fetch("ci_readiness")).to include(
        "verdict" => "READY",
        "required_used" => true
      )
      expect(ledger.fetch("ci_readiness").fetch("pending")).to be_empty
      expect(ledger.fetch("violations")).to be_empty
      expect(File.read(File.join(bin_dir, "pr-check-calls")).strip).to eq("2")
    end
  end

  it "retries transient gh pr checks failures before deriving CI readiness" do
    fake_gh = fake_gh_script_with_check_rows(
      required_json: <<~JSON,
        [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
      full_json: <<~JSON,
        [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
      fail_first_pr_checks: "HTTP 429 Too Many Requests"
    )

    with_raw_fake_gh(fake_gh) do |env, bin_dir|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      ledger = JSON.parse(stdout).fetch("pull_requests").fetch(0)
      expect(ledger.fetch("ci_readiness")).to include(
        "verdict" => "READY",
        "required_used" => true
      )
      expect(File.read(File.join(bin_dir, "pr-check-calls")).strip).to eq("3")
    end
  end

  it "bounds repeated gh pr checks timeouts before reporting unknown CI readiness" do
    fake_gh = fake_gh_script_with_check_rows(
      required_json: "[]",
      full_json: "[]",
      pr_checks_sleep_seconds: "2"
    )

    with_raw_fake_gh(fake_gh) do |env, bin_dir|
      stdout, stderr, status = Open3.capture3(
        env.merge("PR_MERGE_LEDGER_GITHUB_API_TIMEOUT_SECONDS" => "1"),
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("unknown_fields").map { |field| field.fetch("field") }).to include(
        "ci_readiness.verdict"
      )
      expect(File.read(File.join(bin_dir, "pr-check-calls")).strip).to eq("3")
    end
  end

  it "retries timeout-like gh pr checks stderr before reporting unknown CI readiness" do
    fake_gh = fake_gh_script_with_check_rows(
      required_json: "[]",
      full_json: "[]",
      pr_checks_exit_status: 1,
      pr_checks_stderr: "gh pr checks timed out after 404 seconds"
    )

    with_raw_fake_gh(fake_gh) do |env, bin_dir|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("unknown_fields").map { |field| field.fetch("field") }).to include(
        "ci_readiness.verdict"
      )
      expect(report.fetch("pull_requests").fetch(0).fetch("ci_readiness").fetch("message")).to include(
        "gh pr checks required failed with exit 1: gh pr checks timed out after 404 seconds"
      )
      expect(File.read(File.join(bin_dir, "pr-check-calls")).strip).to eq("6")
    end
  end

  it "blocks strict live closeout when full checks omit required rows" do
    fake_gh = <<~SH
      #!/bin/sh
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
        required=false
        for arg in "$@"; do
          if [ "$arg" = "--required" ]; then
            required=true
          fi
        done

        if [ "$required" = "true" ]; then
          cat <<'JSON'
      [{"name":"required-pr-gate","state":"SUCCESS","bucket":"pass","link":"https://example.com/check"}]
      JSON
        else
          cat <<'JSON'
      [{"name":"docs-format-check","state":"SUCCESS","bucket":"pass","link":"https://example.com/docs"}]
      JSON
        fi
        exit 0
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    Dir.mktmpdir("pr-merge-ledger-gh") do |bin_dir|
      gh_path = File.join(bin_dir, "gh")
      File.write(gh_path, fake_gh)
      File.chmod(0o755, gh_path)

      stdout, stderr, status = Open3.capture3(
        { "PATH" => "#{bin_dir}:#{ENV.fetch('PATH', '')}" },
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr
      expect(stderr).to include("ledger violations:")

      report = JSON.parse(stdout)
      ledger = report.fetch("pull_requests").fetch(0)
      expect(ledger.fetch("ci_readiness")).to include(
        "verdict" => "UNKNOWN",
        "required_used" => false,
        "message" => "full current-head check list omitted required checks: required-pr-gate"
      )
      expect(ledger.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_ci_readiness"
      )
    end
  end

  it "aggregates multiple live PR ledgers in one invocation" do
    fake_gh = <<~SH
      #!/bin/sh
      pr=""
      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              pr=*) pr=${1#pr=} ;;
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      review_decision="APPROVED"
      if [ "$pr" = "2" ]; then
        review_decision="REVIEW_REQUIRED"
      fi

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"number":$pr,"title":"PR $pr","url":"https://example.com/pr/$pr","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-$pr","headRefOid":"head-$pr","mergedAt":null,"reviewDecision":"$review_decision","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "2",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.dig("source", "prs")).to eq([1, 2])
      expect(report.fetch("pull_requests").map { |ledger| ledger.dig("pr", "number") }).to eq([1, 2])
      expect(report.fetch("complete_allowed")).to be(false)
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "review_decision_review_required"
      )
    end
  end

  it "does not report another PR's disposition key as unused in multi-PR aggregate mode" do
    fake_gh = <<~SH
      #!/bin/sh
      pr=""
      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              pr=*) pr=${1#pr=} ;;
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"number":$pr,"title":"PR $pr","url":"https://example.com/pr/$pr","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-$pr","headRefOid":"head-$pr","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif [ "$pr" = "1" ]; then
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[{"id":"comment-1","url":"https://example.com/pr/1#issuecomment-1","author":{"login":"reviewer"},"createdAt":"2026-06-01T00:00:00Z","body":"[P2] Dispositioned finding."}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<JSON
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    Tempfile.create(["pr-merge-ledger-multi-pr-dispositions", ".json"]) do |dispositions_file|
      dispositions_file.write(
        JSON.generate(
          "https://example.com/pr/1#issuecomment-1#L1" => {
            "disposition" => "fixed",
            "evidence" => "Handled in the fixture."
          }
        )
      )
      dispositions_file.flush

      with_fake_gh(fake_gh) do |env|
        stdout, stderr, status = Open3.capture3(
          env,
          script_path,
          "1",
          "2",
          "--repo",
          "shakacode/react_on_rails",
          "--finding-dispositions",
          dispositions_file.path,
          chdir: repo_root
        )

        expect(status).to be_success, stderr
        expect(stderr).not_to include("unused disposition keys")

        report = JSON.parse(stdout)
        unused_keys_by_pr = report.fetch("pull_requests").map do |ledger|
          ledger.dig("priority_finding_dispositions", "unused_keys")
        end
        expect(unused_keys_by_pr).to eq([[], []])
        expect(report.fetch("unknown_fields").map { |field| field.fetch("field") }).not_to include(
          "priority_finding_dispositions.unused_keys"
        )
      end
    end
  end

  it "rejects strict multiple live PR ledgers before producing an incomplete gate result" do
    stdout, stderr, status = Open3.capture3(
      script_path,
      "1",
      "2",
      "--repo",
      "shakacode/react_on_rails",
      "--strict",
      chdir: repo_root
    )

    expect(status).not_to be_success
    expect(stdout).to eq("")
    expect(stderr).to include(
      "pr-merge-ledger: --strict with multiple PRs requires separate per-PR runs with explicit " \
      "--changelog-classification"
    )
  end

  it "paginates live review-thread comments before normalizing threads" do
    fake_gh = <<~SH
      #!/bin/sh
      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'node(id:$threadId)'; then
        cat <<'JSON'
      {"data":{"repository":{"id":"repo-id"},"node":{"comments":{"nodes":[{"id":"comment-2","databaseId":2,"body":"second page","author":{"login":"reviewer"},"url":"https://example.com/comment-2","path":"script/pr-merge-ledger","line":1,"createdAt":"2026-06-02T00:00:00Z","outdated":false,"commit":{"oid":"head-1"},"pullRequestReview":{"id":"review-1","state":"COMMENTED","submittedAt":"2026-06-02T00:00:00Z","commit":{"oid":"head-1"},"author":{"login":"reviewer"}}}],"pageInfo":{"hasNextPage":false,"endCursor":"cursor-2"}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"id":"thread-1","isResolved":false,"isOutdated":false,"path":"script/pr-merge-ledger","line":1,"comments":{"nodes":[{"id":"comment-1","databaseId":1,"body":"first page","author":{"login":"reviewer"},"url":"https://example.com/comment-1","path":"script/pr-merge-ledger","line":1,"createdAt":"2026-06-01T00:00:00Z","outdated":false,"commit":{"oid":"head-1"},"pullRequestReview":{"id":"review-1","state":"COMMENTED","submittedAt":"2026-06-01T00:00:00Z","commit":{"oid":"head-1"},"author":{"login":"reviewer"}}}],"pageInfo":{"hasNextPage":true,"endCursor":"cursor-1"}}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).not_to be_success, stderr

      report = JSON.parse(stdout)
      thread = report.dig("pull_requests", 0, "unresolved_current_head_review_threads", "threads", 0)
      expect(thread.fetch("comments_complete")).to be(true)
      expect(thread.fetch("comments").map { |comment| comment.fetch("id") }).to eq(%w[comment-1 comment-2])
      expect(report.fetch("unknown_fields").map { |field| field.fetch("field") }).not_to include(
        "review_threads.comments"
      )
    end
  end

  it "prints GraphQL response errors from gh API calls" do
    fake_gh = <<~SH
      #!/bin/sh
      cat <<'JSON'
      {"data":null,"errors":[{"message":"rate limit exceeded"},{"message":"bad credentials"}]}
      JSON
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("gh api graphql returned errors: rate limit exceeded; bad credentials")
    end
  end

  it "retries failed gh API calls before reporting the live ledger" do
    fake_gh = <<~SH
      #!/bin/sh
      count_file="$(dirname "$0")/failed-once"
      if [ ! -f "$count_file" ]; then
        touch "$count_file"
        printf '%s\\n' 'temporary gateway failure' >&2
        exit 1
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      expect(status).to be_success, stderr

      report = JSON.parse(stdout)
      expect(report.fetch("complete_allowed")).to be(true)
    end
  end

  it "does not retry 422 gh API failures" do
    fake_gh = <<~SH
      #!/bin/sh
      count_file="$(dirname "$0")/failed-422-once"
      if [ ! -f "$count_file" ]; then
        touch "$count_file"
        printf '%s\\n' 'HTTP 422 temporary validation window' >&2
        exit 1
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        "--changelog-classification",
        "not_user_visible",
        "--strict",
        chdir: repo_root
      )

      count_path = File.join(env.fetch("PATH").split(":").first, "failed-422-once")
      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("HTTP 422 temporary validation window")
      expect(File.read(count_path).strip).to be_empty
    end
  end

  it "retries GitHub secondary rate-limit responses" do
    fake_gh = <<~SH
      #!/bin/sh
      count_file="$(dirname "$0")/calls"
      count=0
      if [ -f "$count_file" ]; then
        count=$(cat "$count_file")
      fi
      count=$((count + 1))
      printf '%s\\n' "$count" > "$count_file"

      if [ "$count" -eq 1 ]; then
        printf '%s\\n' 'HTTP 429 Too Many Requests' >&2
        exit 1
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*)
                query=${1#query=}
                ;;
            esac
            ;;
          query=*)
            query=${1#query=}
            ;;
          query)
            shift
            if [ "$#" -gt 0 ]; then
              query=$1
            fi
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      count_path = File.join(env.fetch("PATH").split(":").first, "calls")
      expect(status).to be_success
      expect(stderr).to be_empty
      expect(JSON.parse(stdout).dig("pull_requests", 0, "pr", "number")).to eq(1)
      expect(File.read(count_path).strip).to eq("5")
    end
  end

  it "retries GitHub 403 secondary rate-limit responses" do
    fake_gh = <<~SH
      #!/bin/sh
      count_file="$(dirname "$0")/calls"
      count=0
      if [ -f "$count_file" ]; then
        count=$(cat "$count_file")
      fi
      count=$((count + 1))
      printf '%s\\n' "$count" > "$count_file"

      if [ "$count" -eq 1 ]; then
        printf '%s\\n' 'HTTP 403 API rate limit exceeded' >&2
        exit 1
      fi

      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*)
                query=${1#query=}
                ;;
            esac
            ;;
          query=*)
            query=${1#query=}
            ;;
          query)
            shift
            if [ "$#" -gt 0 ]; then
              query=$1
            fi
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      count_path = File.join(env.fetch("PATH").split(":").first, "calls")
      expect(status).to be_success
      expect(stderr).to be_empty
      expect(JSON.parse(stdout).dig("pull_requests", 0, "pr", "number")).to eq(1)
      expect(File.read(count_path).strip).to eq("5")
    end
  end

  it "fails when GraphQL pagination cursors stop advancing" do
    fake_gh = <<~SH
      #!/bin/sh
      cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"Title","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch","headRefOid":"abc123","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"same"}}}}}}
      JSON
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pagination cursor did not advance for files")
    end
  end

  it "fails when GraphQL pagination returns an empty cursor" do
    fake_gh = <<~SH
      #!/bin/sh
      cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"Title","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch","headRefOid":"abc123","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":""}}}}}}
      JSON
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pagination cursor did not advance for files")
    end
  end

  it "rejects GraphQL variables that gh would read from files" do
    fake_gh = <<~SH
      #!/bin/sh
      cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"Title","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch","headRefOid":"abc123","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"@secret"}}}}}}
      JSON
    SH

    with_fake_gh(fake_gh) do |env|
      stdout, stderr, status = Open3.capture3(
        env,
        script_path,
        "1",
        "--repo",
        "shakacode/react_on_rails",
        chdir: repo_root
      )

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("gh api graphql variable endCursor cannot start with @")
    end
  end

  it "accepts object finding dispositions with evidence" do
    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 8,
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [
        {
          "id" => "comment-2",
          "url" => "https://example.com/comment-2",
          "body" => "MUST-FIX: top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }
    dispositions = {
      "comment-2" => {
        "disposition" => "explicitly_waived",
        "evidence" => "maintainer waiver"
      }
    }

    Tempfile.create(["pr-merge-ledger-disposition-fixture", ".json"]) do |fixture_file|
      Tempfile.create(["pr-merge-ledger-dispositions", ".json"]) do |dispositions_file|
        write_fixture(fixture_file, fixture)
        fixture_file.flush
        dispositions_file.write(JSON.generate(dispositions))
        dispositions_file.flush

        stdout, stderr, status = Open3.capture3(
          script_path,
          "--fixture",
          fixture_file.path,
          "--changelog-classification",
          "not_user_visible",
          "--finding-dispositions",
          dispositions_file.path,
          "--strict",
          chdir: repo_root
        )

        expect(status).to be_success, stderr

        report = JSON.parse(stdout)
        pr_ledger = report.fetch("pull_requests").first
        expect(report.fetch("complete_allowed")).to be(true)
        expect(pr_ledger.dig("priority_finding_dispositions", "findings").first).to include(
          "id" => "comment-2",
          "disposition" => "explicitly_waived",
          "evidence" => "maintainer waiver"
        )
      end
    end
  end

  # Regression: GitHub review/comment bodies from bot reviewers (coderabbitai,
  # codex) routinely contain UTF-8 such as em-dashes and emoji. The script is a
  # standalone tool run outside any bundle, so it resolves the Ruby-shipped json
  # gem. Modern json (>= ~2.8) raises Encoding::InvalidByteSequenceError ("\xE2"
  # on US-ASCII) when JSON.parse receives UTF-8 bytes tagged US-ASCII -- which is
  # what happens under a non-UTF-8 locale (LANG/LC_ALL unset). The script must
  # pin UTF-8 regardless of locale.
  #
  # These tests deliberately run the script with Bundler.with_unbundled_env so it
  # uses the system json (the strict one users hit), not this suite's pinned json
  # 2.7.2, which silently tolerates the mistagged bytes and would mask the bug.
  # When the unbundled json is too old to be strict, the regression cannot be
  # reproduced, so the test skips rather than passing as a no-op.
  def ascii_locale_env
    {
      "LANG" => "C",
      "LC_ALL" => "C",
      "LC_CTYPE" => nil
    }.freeze
  end

  def with_unbundled_env(&)
    require "bundler"
    Bundler.with_unbundled_env(&)
  end

  def unbundled_json_rejects_mistagged_utf8?
    # The probe result is process-wide (it only depends on the system json gem),
    # so spawn at most one subprocess per suite run. RSpec runs each example in a
    # fresh instance, so memoize on the example-group class -- which is shared --
    # rather than an instance variable, which would not persist across examples.
    memo = self.class.instance_variable_get(:@unbundled_json_rejects_mistagged_utf8)
    # Three-state: nil = not probed yet, false = tolerant json, true = strict json.
    return memo unless memo.nil?

    # {"k":"<em-dash>"} as raw UTF-8 bytes, deliberately mislabeled US-ASCII.
    probe = <<~RUBY
      require "json"
      bytes = [0x7b, 0x22, 0x6b, 0x22, 0x3a, 0x22, 0xe2, 0x80, 0x94, 0x22, 0x7d]
      mistagged = bytes.pack("C*").force_encoding("US-ASCII")
      begin
        JSON.parse(mistagged)
        print "tolerant"
      rescue EncodingError
        print "strict"
      end
    RUBY
    result = with_unbundled_env do
      out, = Open3.capture2(ascii_locale_env, "ruby", "-e", probe)
      out == "strict"
    end
    self.class.instance_variable_set(:@unbundled_json_rejects_mistagged_utf8, result)
  end

  it "parses non-ASCII GraphQL review-thread bodies under a US-ASCII locale" do
    skip "system json tolerates mistagged UTF-8; cannot reproduce" unless unbundled_json_rejects_mistagged_utf8?

    fake_gh = <<~SH
      #!/bin/sh
      query=""
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|-F)
            shift
            case "$1" in
              query=*) query=${1#query=} ;;
            esac
            ;;
        esac
        shift
      done

      if printf '%s' "$query" | grep -q 'files(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"number":1,"title":"PR 1","url":"https://example.com/pr/1","state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"branch-1","headRefOid":"head-1","mergedAt":null,"reviewDecision":"APPROVED","files":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviewThreads'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"id":"thread-1","isResolved":false,"isOutdated":false,"path":"script/pr-merge-ledger","line":1,"comments":{"nodes":[{"id":"comment-1","databaseId":1,"body":"Consider this — it has an em-dash and an emoji 🎉 from coderabbitai.","author":{"login":"coderabbitai"},"url":"https://example.com/comment-1","path":"script/pr-merge-ledger","line":1,"createdAt":"2026-06-01T00:00:00Z","outdated":false,"commit":{"oid":"head-1"},"pullRequestReview":{"id":"review-1","state":"COMMENTED","submittedAt":"2026-06-01T00:00:00Z","commit":{"oid":"head-1"},"author":{"login":"coderabbitai"}}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      elif printf '%s' "$query" | grep -q 'reviews(first'; then
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      else
        cat <<'JSON'
      {"data":{"repository":{"pullRequest":{"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}
      JSON
      fi
    SH

    with_unbundled_env do
      with_fake_gh(fake_gh) do |env|
        stdout, stderr, status = Open3.capture3(
          env.merge(ascii_locale_env),
          script_path,
          "1",
          "--repo",
          "shakacode/react_on_rails",
          "--changelog-classification",
          "not_user_visible",
          chdir: repo_root
        )

        expect(status).to be_success, stderr
        expect(stderr).not_to include("InvalidByteSequenceError")

        report = JSON.parse(stdout)
        excerpt = report.dig(
          "pull_requests", 0, "unresolved_current_head_review_threads", "threads", 0, "body_excerpt"
        )
        expect(excerpt).to include("em-dash")
        expect(excerpt).to include("—")
        expect(excerpt).to include("🎉")
      end
    end
  end

  it "parses non-ASCII fixture bodies under a US-ASCII locale" do
    skip "system json tolerates mistagged UTF-8; cannot reproduce" unless unbundled_json_rejects_mistagged_utf8?

    fixture = {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => 4106,
        "title" => "Wrap generated demo file paths — with em-dash 🎉",
        "headRefOid" => "abc123",
        "reviewDecision" => "APPROVED"
      },
      "files" => [],
      "review_threads" => [],
      "reviews" => [],
      "comments" => []
    }

    Tempfile.create(["pr-merge-ledger-non-ascii", ".json"]) do |file|
      file.binmode
      write_fixture(file, fixture, binary: true)
      file.flush

      stdout, stderr, status = with_unbundled_env do
        Open3.capture3(
          ascii_locale_env,
          script_path,
          "--fixture",
          file.path,
          "--changelog-classification",
          "not_user_visible",
          "--strict",
          chdir: repo_root
        )
      end

      expect(status).to be_success, stderr
      expect(stderr).not_to include("InvalidByteSequenceError")

      report = JSON.parse(stdout)
      expect(report.dig("pull_requests", 0, "pr", "title")).to include("—")
      expect(report.dig("pull_requests", 0, "pr", "title")).to include("🎉")
    end
  end

  it "prints the fixed JSON schema" do
    stdout, stderr, status = Open3.capture3(script_path, "--schema", chdir: repo_root)

    expect(status).to be_success, stderr

    schema = JSON.parse(stdout)
    expect(schema.fetch("$id")).to eq(
      "https://raw.githubusercontent.com/shakacode/react_on_rails/main/script/pr-merge-ledger.schema.json"
    )
    expect(schema.dig("properties", "$schema", "const")).to eq(
      "https://raw.githubusercontent.com/shakacode/react_on_rails/main/script/pr-merge-ledger.schema.json"
    )
    expect(schema.dig("properties", "schema_version", "const")).to eq("pr-merge-ledger/v1")
    expect(schema.fetch("required")).to include("pull_requests", "violations", "complete_allowed")
    expect(schema.dig("$defs", "pull_request_ledger", "additionalProperties")).to be(false)
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "pr", "additionalProperties")).to be(false)
    expected_review_decision_enum = %w[APPROVED CHANGES_REQUESTED REVIEW_REQUIRED NOT_REQUIRED UNKNOWN]
    pr_review_decision_enum = schema.dig(
      "$defs", "pull_request_ledger", "properties", "pr", "properties", "review_decision", "enum"
    )
    review_objects_decision_enum = schema.dig(
      "$defs", "pull_request_ledger", "properties", "review_objects", "properties", "review_decision", "enum"
    )

    expect(pr_review_decision_enum).to eq(expected_review_decision_enum)
    expect(review_objects_decision_enum).to eq(expected_review_decision_enum)
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "lockfile_diff", "properties",
                      "has_lockfile_diff")).to eq("enum" => [true, false, "UNKNOWN"])
    expect(schema.dig("$defs", "pull_request_ledger", "required")).to include("issue_comments")
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "violations", "type")).to eq("array")
    expect(
      schema.dig("$defs", "pull_request_ledger", "properties", "unresolved_current_head_review_threads",
                 "properties", "threads", "items", "$ref")
    ).to eq("#/$defs/review_thread")
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "issue_comments", "items", "$ref")).to eq(
      "#/$defs/issue_comment"
    )
    expect(schema.dig("$defs", "review_thread_comment", "properties", "author_association", "type")).to eq(
      %w[string null]
    )
    expect(
      schema.dig("$defs", "pull_request_ledger", "properties", "priority_finding_dispositions", "properties",
                 "findings", "items", "$ref")
    ).to eq("#/$defs/priority_finding")
    expect(
      schema.dig("$defs", "pull_request_ledger", "properties", "priority_finding_dispositions", "properties",
                 "truncated_sources", "items", "$ref")
    ).to eq("#/$defs/priority_finding_truncated_source")
    expect(
      schema.dig("$defs", "pull_request_ledger", "properties", "priority_finding_dispositions", "required")
    ).to include("unused_keys")
    expect(
      schema.dig("$defs", "pull_request_ledger", "properties", "priority_finding_dispositions", "properties",
                 "unused_keys", "items", "type")
    ).to eq("string")
    expect(schema.dig("$defs", "violation", "additionalProperties")).to be(false)
    expect(schema.dig("$defs", "violation", "properties")).to include(
      "path", "line", "reviewer", "head_sha", "current_head"
    )
    expect(schema.dig("$defs", "violation", "properties", "reviewer", "type")).to eq(%w[string null])
    expect(schema.dig("$defs", "review_thread", "additionalProperties")).to be(false)
    expect(schema.dig("$defs", "review_thread_comment", "properties", "reply_to_id", "type")).to eq(
      %w[string null]
    )
    expect(schema.dig("$defs", "review_object", "required")).to include("body_excerpt")
    expect(schema.dig("$defs", "review_object", "properties")).not_to include("body_text")
    expect(schema.dig("$defs", "issue_comment", "required")).to include("body_excerpt")
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "unknown_fields", "type")).to eq("array")
    expect(schema.dig("$defs", "pull_request_ledger", "properties", "complete_allowed", "type")).to eq("boolean")
  end
end
