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
      File.write(gh_path, script_body)
      File.chmod(0o755, gh_path)

      yield({ "PATH" => "#{bin_dir}:#{ENV.fetch('PATH', '')}" })
    end
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
    expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings").first).to include(
      "severity" => "P2",
      "disposition" => "UNKNOWN"
    )
    expect(pr_ledger.dig("changelog_classification", "classification")).to eq("not_user_visible")
    expect(pr_ledger.dig("lockfile_diff", "has_lockfile_diff")).to be(false)
    expect(violation_codes).to include(
      "review_decision_changes_requested",
      "unresolved_current_head_review_thread",
      "unknown_p1_p2_must_fix_disposition"
    )
    expect(violation_codes).not_to include("changes_requested_review_object")
  end

  it "blocks UNKNOWN review decisions in strict mode" do
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

    Tempfile.create(["pr-merge-ledger-unknown", ".json"]) do |file|
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
        file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
      file.flush

      stdout, stderr, status = Open3.capture3(script_path, "--fixture", file.path, chdir: repo_root)

      expect(status.exitstatus).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("pr-merge-ledger: fixture is missing pull_request")
      expect(stderr).not_to include("from ")
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings")).to be_empty
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
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings").first).to include(
        "id" => "critical-review",
        "severity" => "P0",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_p1_p2_must_fix_disposition"
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
      file.write(JSON.generate(fixture))
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
      finding = report.dig("pull_requests", 0, "p1_p2_must_fix_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "badge-review",
        "severity" => "P2",
        "disposition" => "UNKNOWN"
      )
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
      file.write(JSON.generate(fixture))
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
      findings = pr_ledger.dig("p1_p2_must_fix_dispositions", "findings")
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
      file.write(JSON.generate(fixture))
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
      findings = report.dig("pull_requests", 0, "p1_p2_must_fix_dispositions", "findings")
      expect(findings.length).to eq(1)
      expect(findings.first).to include(
        "severity" => "MUST_FIX",
        "text_excerpt" => "MUST-FIX [P1]: duplicated severity markers."
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
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings")).to be_empty
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
      file.write(JSON.generate(fixture))
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
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unresolved_current_head_review_thread"
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
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings")).to be_empty
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
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings")).to be_empty
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
      file.write(JSON.generate(fixture))
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
      finding = report.dig("pull_requests", 0, "p1_p2_must_fix_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "open-review",
        "severity" => "P1",
        "text_excerpt" => "[P1] issue not resolved",
        "disposition" => "UNKNOWN"
      )
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
      file.write(JSON.generate(fixture))
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
      finding = report.dig("pull_requests", 0, "p1_p2_must_fix_dispositions", "findings", 0)
      expect(finding).to include(
        "id" => "mixed-review",
        "severity" => "P1",
        "text_excerpt" => "P1 issues: resolved; P0 still open",
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
      file.write(JSON.generate(fixture))
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
      expect(report.dig("pull_requests", 0, "p1_p2_must_fix_dispositions", "findings")).to be_empty
    end
  end

  it "blocks P1/P2/Must-Fix findings from top-level PR comments" do
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
          "body" => "[P1] Top-level PR comment finding.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-top-level-comment", ".json"]) do |file|
      file.write(JSON.generate(fixture))
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
      expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings").first).to include(
        "id" => "comment-1",
        "severity" => "P1",
        "disposition" => "UNKNOWN"
      )
      expect(report.fetch("violations").map { |violation| violation.fetch("code") }).to include(
        "unknown_p1_p2_must_fix_disposition"
      )
    end
  end

  it "keeps full issue comment bodies out of the output ledger" do
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
          "body" => "A long informational comment that should be excerpted in output.",
          "author" => { "login" => "reviewer" },
          "createdAt" => "2026-06-01T00:00:00Z"
        }
      ]
    }

    Tempfile.create(["pr-merge-ledger-issue-comment-body", ".json"]) do |file|
      file.write(JSON.generate(fixture))
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
      expect(issue_comment).to include(
        "body_excerpt" => "A long informational comment that should be excerpted in output."
      )
      expect(issue_comment).not_to have_key("body")
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
      file.write(JSON.generate(fixture))
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
      file.write(JSON.generate(fixture))
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
        fixture_file.write(JSON.generate(fixture))
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
        expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings").first).to include(
          "id" => "comment-1",
          "disposition" => "fixed"
        )
      end
    end
  end

  it "warns when finding disposition keys do not match any finding" do
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
        fixture_file.write(JSON.generate(fixture))
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
        expect(stderr).to include("unused disposition keys: https://example.com/typo")

        report = JSON.parse(stdout)
        expect(report.fetch("complete_allowed")).to be(true)
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
        fixture_file.write(JSON.generate(fixture))
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
        fixture_file.write(JSON.generate(fixture))
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
        expect(pr_ledger.dig("p1_p2_must_fix_dispositions", "findings").first).to include(
          "id" => "comment-2",
          "disposition" => "explicitly_waived",
          "evidence" => "maintainer waiver"
        )
      end
    end
  end

  it "prints the fixed JSON schema" do
    stdout, stderr, status = Open3.capture3(script_path, "--schema", chdir: repo_root)

    expect(status).to be_success, stderr

    schema = JSON.parse(stdout)
    expect(schema.fetch("$id")).to eq("https://reactonrails.com/schemas/pr-merge-ledger-v1.json")
    expect(schema.dig("properties", "schema_version", "const")).to eq("pr-merge-ledger/v1")
    expect(schema.fetch("required")).to include("pull_requests", "violations", "complete_allowed")
    expect(schema.dig("$defs", "pull_request_ledger", "required")).to include("issue_comments")
  end
end
