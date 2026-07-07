# frozen_string_literal: true

require "json"
require "open3"

SCRIPT = File.expand_path("ci-required-merge-group-gate", __dir__)
PACKAGE_JS_WORKFLOW = "JS unit tests for Renderer package"

def check_run(name:, status: "completed", conclusion: "success", id: 1, check_suite_id: 100)
  {
    "id" => id,
    "name" => name,
    "check_suite" => { "id" => check_suite_id },
    "status" => status,
    "conclusion" => conclusion,
    "created_at" => "2026-07-07T00:00:#{format('%02d', id)}Z",
    "started_at" => "2026-07-07T00:00:#{format('%02d', id)}Z",
    "completed_at" => status == "completed" ? "2026-07-07T00:00:#{format('%02d', id)}Z" : nil,
    "html_url" => "https://example.test/check-runs/#{id}"
  }.compact
end

def action_run(name: PACKAGE_JS_WORKFLOW, check_suite_id: 100)
  {
    "id" => check_suite_id,
    "name" => name,
    "check_suite_id" => check_suite_id
  }
end

def check_runs_payload(*check_runs)
  JSON.generate("check_runs" => check_runs)
end

def action_runs_payload(*action_runs)
  JSON.generate("workflow_runs" => action_runs)
end

class Runner
  def initialize
    @tests = []
    @failures = []
  end

  def run_case(name, env:, expected_status:, expected_output:)
    @tests << name
    puts "-> #{name}"

    base_env = {
      "GITHUB_EVENT_NAME" => "merge_group",
      "REQUIRE_PACKAGE_JS_BUILD_20" => "true",
      "CI_REQUIRED_MERGE_GROUP_GATE_TIMEOUT_SECONDS" => "0",
      "CI_REQUIRED_MERGE_GROUP_GATE_POLL_SECONDS" => "0",
      "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
      "GITHUB_SHA" => "abc123",
      "CI_REQUIRED_ACTION_RUNS_JSON" => action_runs_payload(action_run)
    }

    stdout, stderr, status = Open3.capture3(base_env.merge(env), "ruby", SCRIPT)
    output = "#{stdout}\n#{stderr}"

    return if status.exitstatus == expected_status && output.include?(expected_output)

    @failures << <<~MSG
      #{name}: expected status #{expected_status} and output containing #{expected_output.inspect}
        got status #{status.exitstatus}
        stdout: #{stdout}
        stderr: #{stderr}
    MSG
  end

  def finish
    if @failures.any?
      warn
      warn "#{@failures.length} of #{@tests.length} tests failed"
      warn @failures.join("\n")
      exit 1
    end

    puts
    puts "#{@tests.length} merge-group gate tests passed"
  end
end

runner = Runner.new

runner.run_case(
  "skips non-merge-group events",
  env: {
    "GITHUB_EVENT_NAME" => "pull_request",
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload
  },
  expected_status: 0,
  expected_output: "Merge-group full-matrix gate skipped."
)

runner.run_case(
  "skips when JS tests are not relevant",
  env: {
    "REQUIRE_PACKAGE_JS_BUILD_20" => "false",
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload
  },
  expected_status: 0,
  expected_output: "Merge-group full-matrix gate skipped."
)

runner.run_case(
  "passes when the package JS minimum Node check succeeds",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(check_run(name: "build (20)"))
  },
  expected_status: 0,
  expected_output: "Required merge-group check(s) passed."
)

runner.run_case(
  "matches the workflow-prefixed check alias from the actions run check suite",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(check_run(name: "build (20)", check_suite_id: 200)),
    "CI_REQUIRED_ACTION_RUNS_JSON" => action_runs_payload(action_run(check_suite_id: 200))
  },
  expected_status: 0,
  expected_output: "Required merge-group check(s) passed."
)

runner.run_case(
  "does not match a bare check name from another workflow",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(check_run(name: "build (20)", check_suite_id: 300)),
    "CI_REQUIRED_ACTION_RUNS_JSON" => action_runs_payload(
      action_run(name: "Unrelated Workflow", check_suite_id: 300)
    )
  },
  expected_status: 1,
  expected_output: "#{PACKAGE_JS_WORKFLOW} / build (20): missing"
)

runner.run_case(
  "fails closed when configured required groups parse empty",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(check_run(name: "build (20)")),
    "CI_REQUIRED_MERGE_GROUP_REQUIRED_CHECKS" => "|||"
  },
  expected_status: 1,
  expected_output: "CI_REQUIRED_MERGE_GROUP_REQUIRED_CHECKS did not contain any check aliases"
)

runner.run_case(
  "fails when the package JS minimum Node check fails",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(
      check_run(name: "build (20)", conclusion: "failure")
    )
  },
  expected_status: 1,
  expected_output: "concluded failure"
)

runner.run_case(
  "fails closed when the required check is missing",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload
  },
  expected_status: 1,
  expected_output: "Timed out waiting for required merge-group check(s):"
)

runner.run_case(
  "fails closed while the required check is still running",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(
      check_run(name: "build (20)", status: "in_progress", conclusion: nil)
    )
  },
  expected_status: 1,
  expected_output: "build (20): in_progress"
)

runner.run_case(
  "uses the latest attempt for duplicate check names",
  env: {
    "CI_REQUIRED_CHECK_RUNS_JSON" => check_runs_payload(
      check_run(name: "build (20)", conclusion: "failure", id: 1),
      check_run(name: "build (20)", conclusion: "success", id: 2)
    )
  },
  expected_status: 0,
  expected_output: "Required merge-group check(s) passed."
)

runner.finish
