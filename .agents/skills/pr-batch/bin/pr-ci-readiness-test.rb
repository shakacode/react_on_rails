#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for pr-ci-readiness.
# Run with: ruby .agents/skills/pr-batch/bin/pr-ci-readiness-test.rb

require "minitest/autorun"
require "open3"
require "json"
require "tmpdir"
require "fileutils"

SCRIPT = File.expand_path("pr-ci-readiness", __dir__)
load SCRIPT

class PrCiReadinessTest < Minitest::Test
  # --- Pure verdict logic (module_function), tested directly ---------------

  def test_all_passing_is_ready
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "examples", "bucket" => "skipping" }
                               ])
    assert_equal "READY", out["verdict"]
    assert_equal true, out["required_used"]
    assert_empty out["failing"]
    assert_empty out["pending"]
  end

  def test_failing_is_not_ready_with_name_surfaced
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "lint", "bucket" => "fail" }
                               ])
    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["lint"], out["failing"]
    assert_empty out["pending"]
  end

  def test_pending_is_not_ready
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "build", "bucket" => "pending" }
                               ])
    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["build"], out["pending"]
  end

  def test_empty_rows_is_unknown
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [])
    assert_equal "UNKNOWN", out["verdict"]
  end

  def test_cancel_only_is_unknown
    out = PrCiReadiness.assess(pr_number: 1, required_used: false,
                               rows: [{ "name" => "stale", "bucket" => "cancel" }])
    assert_equal "UNKNOWN", out["verdict"]
  end

  def test_cancel_row_does_not_mask_passing
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "stale", "bucket" => "cancel" }
                               ])
    assert_equal "READY", out["verdict"]
    assert_empty out["failing"]
  end

  def test_cancel_row_dropped_from_failing_and_pending
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [
                                 { "name" => "lint", "bucket" => "fail" },
                                 { "name" => "stale", "bucket" => "cancel" }
                               ])
    assert_equal ["lint"], out["failing"]
    assert_equal "NOT_READY", out["verdict"]
  end

  # --- parse helpers --------------------------------------------------------

  def test_usable_checks_discriminates_payloads
    assert PrCiReadiness.usable_checks?('[{"name":"a","bucket":"pass"}]')
    refute PrCiReadiness.usable_checks?("[]")
    refute PrCiReadiness.usable_checks?("")
    refute PrCiReadiness.usable_checks?(nil)
    refute PrCiReadiness.usable_checks?("no required checks") # non-JSON message
    # Cancel-only rows are not usable: they must not short-circuit the fallback.
    refute PrCiReadiness.usable_checks?('[{"name":"stale","bucket":"cancel"}]')
  end

  def test_parse_rows_handles_non_array_json
    assert_equal [], PrCiReadiness.parse_rows('{"oops":true}')
  end

  def test_text_summary_format
    out = PrCiReadiness.assess(pr_number: 9, required_used: true, rows: [
                                 { "name" => "lint", "bucket" => "fail" }
                               ])
    text = PrCiReadiness.text_summary(out)
    assert_includes text, "NOT_READY"
    assert_includes text, "required_used: true"
    assert_includes text, "failing: lint"
    assert_includes text, "pending: (none)"
  end
end

# CLI / Runner integration via a fake gh on PATH.
class PrCiReadinessCliTest < Minitest::Test
  # Build a temp dir with a fake `gh` executable that emits canned `gh pr
  # checks` JSON, then run the real script with that dir prepended to PATH.
  def with_fake_gh(required_json:, full_json:)
    Dir.mktmpdir("pr-ci-readiness-test") do |dir|
      gh = File.join(dir, "gh")
      File.write(gh, fake_gh_script(required_json, full_json))
      FileUtils.chmod(0o755, gh)
      env = { "PATH" => "#{dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}" }
      yield env
    end
  end

  # The fake gh handles `gh repo view ...` (so --repo is optional) and
  # `gh pr checks ...`, returning the required vs full payload based on the
  # presence of the --required flag. Non-JSON ("") models "no required checks".
  def fake_gh_script(required_json, full_json)
    <<~SH
      #!/usr/bin/env bash
      if [ "$1" = "repo" ] && [ "$2" = "view" ]; then
        printf 'owner/repo'
        exit 0
      fi
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
        for arg in "$@"; do
          if [ "$arg" = "--required" ]; then
            printf '%s' #{required_json.inspect}
            exit 0
          fi
        done
        printf '%s' #{full_json.inspect}
        exit 0
      fi
      exit 1
    SH
  end

  def run_script(env, *)
    Open3.capture2e(env, "ruby", SCRIPT, *)
  end

  def test_required_checks_used_when_present
    with_fake_gh(
      required_json: '[{"name":"rspec","state":"SUCCESS","bucket":"pass","link":"x"}]',
      full_json: '[{"name":"rspec","bucket":"pass"},{"name":"extra","bucket":"fail"}]'
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_equal true, data["required_used"]
      assert_equal 123, data["pr"]
    end
  end

  def test_falls_back_to_full_when_no_required_checks
    # Empty required payload => fall back to full list, required_used flips false.
    with_fake_gh(
      required_json: "",
      full_json: '[{"name":"lint","state":"FAILURE","bucket":"fail","link":"x"}]'
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_equal ["lint"], data["failing"]
    end
  end

  def test_totally_empty_is_unknown_via_cli
    with_fake_gh(required_json: "", full_json: "[]") do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal false, data["required_used"]
    end
  end

  def test_cancel_only_required_falls_back_to_full_list
    # A required list of only cancelled rows is not usable: it must fall back to
    # the full check list (which here surfaces a real failure) instead of
    # silently collapsing to UNKNOWN.
    with_fake_gh(
      required_json: '[{"name":"stale","state":"CANCELLED","bucket":"cancel","link":"x"}]',
      full_json: '[{"name":"lint","state":"FAILURE","bucket":"fail","link":"x"}]'
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      # required form had no usable rows, so the full list was used.
      assert_equal false, data["required_used"]
      assert_equal ["lint"], data["failing"]
    end
  end

  def test_cancel_only_required_and_empty_full_is_unknown_via_cli
    # Cancel-only required falls back; if the full list is also empty, UNKNOWN.
    with_fake_gh(
      required_json: '[{"name":"stale","state":"CANCELLED","bucket":"cancel","link":"x"}]',
      full_json: "[]"
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal false, data["required_used"]
    end
  end

  def test_cancel_row_does_not_mask_passing_via_cli
    with_fake_gh(
      required_json: '[{"name":"rspec","bucket":"pass"},{"name":"stale","bucket":"cancel"}]',
      full_json: "[]"
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
    end
  end

  def test_text_mode_via_cli
    with_fake_gh(
      required_json: '[{"name":"lint","bucket":"fail"}]',
      full_json: "[]"
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--text")
      assert status.success?, out
      assert_includes out, "NOT_READY"
      assert_includes out, "failing: lint"
    end
  end

  def test_repo_defaults_to_gh_repo_view
    with_fake_gh(
      required_json: '[{"name":"rspec","bucket":"pass"}]',
      full_json: "[]"
    ) do |env|
      out, status = run_script(env, "123")
      assert status.success?, out
      assert_equal "READY", JSON.parse(out)["verdict"]
    end
  end

  # --- arg validation (no gh needed) ---------------------------------------

  def test_rejects_non_integer_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "not-a-number", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_zero_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "0", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_bad_repo_form
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "owneronly")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_extra_path_segment
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "a/b/c")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_empty_owner
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "/repo")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_unknown_option
    out, status = Open3.capture2e("ruby", SCRIPT, "--bogus")
    refute status.success?
    assert_includes out, "unknown option: --bogus"
  end

  def test_help_exits_zero
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")
    assert status.success?, out
    assert_includes out, "Usage: pr-ci-readiness"
  end

  def test_self_check_passes
    out, status = Open3.capture2e("ruby", SCRIPT, "--self-check")
    assert status.success?, out
    assert_includes out, "self-check passed"
  end
end
