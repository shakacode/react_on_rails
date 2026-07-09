# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"

SCRIPT = File.expand_path("pr-merge-ledger", __dir__)

module PrMergeLedgerFixtureHelpers
  private

  def ledger(data)
    data.fetch("pull_requests").fetch(0)
  end

  def violation_codes(data)
    ledger(data).fetch("violations").map { |violation| violation.fetch("code") }
  end

  def unknown_field_names(data)
    ledger(data).fetch("unknown_fields").map { |field| field.fetch("field") }
  end

  def run_fixture(fixture_hash)
    Dir.mktmpdir("pr-merge-ledger-test") do |dir|
      fixture_path = File.join(dir, "fixture.json")
      File.write(fixture_path, JSON.pretty_generate(fixture_hash))
      stdout, stderr, status = Open3.capture3(
        "ruby",
        SCRIPT,
        "--fixture",
        fixture_path,
        "--strict",
        "--changelog-classification",
        "not_user_visible"
      )
      [stdout, status].tap do
        assert_empty stderr unless stderr.include?("ledger violations:")
      end
    end
  end

  def fixture(ci_readiness:, number: 123)
    {
      "repository" => "shakacode/react_on_rails",
      "pull_request" => {
        "number" => number,
        "title" => "Fixture PR",
        "url" => "https://github.com/shakacode/react_on_rails/pull/#{number}",
        "state" => "OPEN",
        "isDraft" => false,
        "baseRefName" => "main",
        "headRefName" => "codex/fixture",
        "headRefOid" => "abc123",
        "mergedAt" => nil,
        "reviewDecision" => "APPROVED",
        "body" => "Fixes #123"
      },
      "files" => ["script/pr-merge-ledger"],
      "review_threads" => [],
      "reviews" => [],
      "comments" => [],
      "ci_readiness" => ci_readiness
    }
  end

  def ci_readiness(verdict:, checks:, number: 123, status: "known", required_used: true, message: nil)
    {
      "pr" => number,
      "status" => status,
      "verdict" => verdict,
      "required_used" => required_used,
      "failing" => checks.select { |check| check["bucket"] == "fail" },
      "pending" => checks.select { |check| check["bucket"] == "pending" },
      "checks" => checks,
      "message" => message
    }.compact
  end

  def ci_check(name, bucket:, state:, link: nil)
    {
      "name" => name,
      "state" => state,
      "bucket" => bucket,
      "link" => link
    }.compact
  end

  def fixture_with_body(body)
    fixture(
      ci_readiness: ci_readiness(
        verdict: "READY",
        checks: [ci_check("required-pr-gate", bucket: "pass", state: "SUCCESS")]
      )
    ).tap do |dataset|
      dataset.fetch("pull_request")["body"] = body
    end
  end
end
