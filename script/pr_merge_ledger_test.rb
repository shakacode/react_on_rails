# frozen_string_literal: true

require "json"
require "minitest/autorun"
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

class PrMergeLedgerClosingKeywordTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  def test_backticked_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This should close the issue, but `Fixes #4410` will not."))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["backticked_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 1, violation.fetch("line")
    assert_match(/`Fixes #4410`/, violation.fetch("message"))
  end

  def test_fenced_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          This should close the issue, but a fenced code block will not.

          ```text
          Fixes #4410
          ```
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 4, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_nested_shorter_fence_keeps_closing_keyword_inside_outer_code_block
    output, status = run_fixture(
      fixture_with_body(
        <<~MARKDOWN
          ````markdown
          ```text
          Fixes #4410
          ```
          ````
        MARKDOWN
      )
    )

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_indented_code_closing_keyword_blocks_strict_closeout
    output, status = run_fixture(fixture_with_body("This will not close.\n\n    Fixes #4410\n"))

    refute status.success?, output
    data = JSON.parse(output)
    assert_equal ["code_formatted_closing_keyword"], violation_codes(data)
    violation = ledger(data).fetch("violations").first
    assert_equal 3, violation.fetch("line")
    assert_match(/Fixes #4410/, violation.fetch("message"))
  end

  def test_plain_closing_keyword_allows_strict_closeout
    output, status = run_fixture(fixture_with_body("Fixes #4410"))

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  def test_plain_closing_keyword_between_inline_code_spans_allows_strict_closeout
    output, status = run_fixture(
      fixture_with_body("Update `ledger` and Fixes #4410 while documenting `keyword`.")
    )

    assert status.success?, output
    data = JSON.parse(output)
    assert data.fetch("complete_allowed")
    assert_empty violation_codes(data)
  end

  private

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
