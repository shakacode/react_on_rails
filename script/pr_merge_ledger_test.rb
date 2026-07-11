# frozen_string_literal: true

require "minitest/autorun"
require_relative "pr_merge_ledger_test_helpers"

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
