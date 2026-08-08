#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"
require "minitest/autorun"

SCRIPT = File.expand_path("closeout-evidence-replay", __dir__)

class CloseoutEvidenceReplayTest < Minitest::Test
  def run_replay(body, expected_head_sha: nil, require_priority_dispositions: false)
    Tempfile.create("closeout-evidence") do |file|
      file.write(body)
      file.flush
      command = ["ruby", SCRIPT]
      command.concat(["--expected-head-sha", expected_head_sha]) if expected_head_sha
      command << "--require-priority-dispositions" if require_priority_dispositions
      command << file.path
      out, status = Open3.capture2e(*command)
      assert status.success?, out
      JSON.parse(out)
    end
  end

  def test_help_describes_required_priority_evidence
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")

    assert status.success?, out
    assert_includes out, "Fail when priority evidence is missing or explicitly not_applicable"
  end

  def test_required_priority_dispositions_reject_missing_marker
    head_sha = "1111111111111111111111111111111111111111"
    data = run_replay(<<~MARKDOWN, require_priority_dispositions: true)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{head_sha}
      tested_at: PR #123 head #{head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_equal [], priority.fetch("findings")
    assert_equal [], priority.fetch("errors")
  end

  def test_optional_missing_priority_marker_has_stable_error_shape
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "NOT_APPLICABLE", priority.fetch("verdict")
    assert_equal [], priority.fetch("errors")
  end

  def test_required_priority_dispositions_reject_not_applicable_marker
    head_sha = "1111111111111111111111111111111111111111"
    data = run_replay(<<~MARKDOWN, expected_head_sha: head_sha, require_priority_dispositions: true)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{head_sha}
      tested_at: PR #123 head #{head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->

      <!-- priority-finding-dispositions v1
      status: not_applicable
      head_sha: #{head_sha}
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_includes priority.fetch("missing"), "finding"
  end

  def test_current_head_not_required_qa_marker_rejects_inconsistent_terminal_fields
    head_sha = "1111111111111111111111111111111111111111"
    data = run_replay(<<~MARKDOWN, expected_head_sha: head_sha)
      <!-- qa-evidence v1
      required: no
      status: satisfied
      head_sha: #{head_sha}
      tested_at: repository head #{head_sha}
      scope: documentation-only change
      automated_checks: not applicable
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "status"
    assert_includes qa.fetch("missing"), "release_blocking"
  end

  def test_historical_not_required_qa_marker_preserves_legacy_terminal_fields
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: no
      status: satisfied
      head_sha: not_applicable
      tested_at: no PR created
      scope: issue disposition only
      automated_checks: not applicable
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    assert_equal "NOT_APPLICABLE", data.fetch("overall_verdict")
    assert_equal "NOT_APPLICABLE", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_expected_final_head_rejects_qa_from_before_post_qa_commit
    qa_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{qa_head_sha}
      tested_at: PR #70 head #{qa_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("qa_evidence").fetch("verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "head_sha"
  end

  def test_expected_final_head_rejects_duplicate_head_sha_and_stale_tested_at
    qa_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{qa_head_sha}
      tested_at: PR #70 head #{qa_head_sha}
      head_sha: #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal ["duplicate scalar key: head_sha"], data.fetch("qa_evidence").fetch("errors")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "tested_at.head_sha"
  end

  def test_expected_final_head_rejects_stale_tested_at_without_duplicate_keys
    qa_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{qa_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_empty data.fetch("qa_evidence").fetch("errors")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "tested_at.head_sha"
  end

  def test_expected_final_head_requires_qa_head_sha
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      tested_at: PR #70 head #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "head_sha"
  end

  def test_expected_final_head_accepts_matching_qa_evidence
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal final_head_sha, data.fetch("qa_evidence").fetch("expected_head_sha")
  end

  def test_expected_final_head_rejects_stale_priority_dispositions
    stale_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->

      <!-- priority-finding-dispositions v1
      head_sha: #{stale_head_sha}
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | evidence=https://example.test/pr/70#discussion_r1
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_includes priority.fetch("missing"), "head_sha"
    assert_equal final_head_sha, priority.fetch("expected_head_sha")
  end

  def test_expected_final_head_rejects_stale_not_applicable_priority_marker
    stale_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->

      <!-- priority-finding-dispositions v1
      status: not_applicable
      head_sha: #{stale_head_sha}
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_includes priority.fetch("missing"), "head_sha"
    assert_equal final_head_sha, priority.fetch("expected_head_sha")
  end

  def test_expected_final_head_uses_current_markers_from_appended_history
    stale_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{stale_head_sha}
      tested_at: PR #70 head #{stale_head_sha}
      scope: old change
      automated_checks: old checks
      manual_checks: old smoke
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: final change
      automated_checks: final checks
      manual_checks: final smoke
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
      <!-- priority-finding-dispositions v1
      head_sha: #{stale_head_sha}
      finding: url=https://example.test/review/old | severity=P1 | disposition=fixed | evidence=https://example.test/pr/70#old
      -->
      <!-- priority-finding-dispositions v1
      head_sha: #{final_head_sha}
      finding: url=https://example.test/review/current | severity=P1 | disposition=fixed | evidence=https://example.test/pr/70#current
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal "SATISFIED", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_equal 1, data.fetch("qa_evidence").fetch("marker_count")
    assert_equal 1, data.fetch("priority_finding_dispositions").fetch("marker_count")
  end

  def test_expected_final_head_aggregates_all_current_head_qa_markers
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: blocked
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: first current-head pass
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: blocked by review regression
      release_blocking: blocked
      process_gap_disposition: checklist+replay
      -->
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: later current-head pass
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "BLOCKED", data.fetch("overall_verdict")
    assert_equal "BLOCKED", qa.fetch("verdict")
    assert_equal 2, qa.fetch("marker_count")
  end

  def test_expected_final_head_does_not_filter_out_duplicate_head_qa_marker
    stale_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: valid current-head evidence
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{stale_head_sha}
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: malformed duplicate-head evidence
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_equal 2, qa.fetch("marker_count")
    assert_includes qa.fetch("errors"), "marker[1].duplicate scalar key: head_sha"
  end

  def test_expected_final_head_aggregates_all_current_head_priority_markers
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
      <!-- priority-finding-dispositions v1
      head_sha: #{final_head_sha}
      finding: url=https://example.test/review/waived | severity=P1 | disposition=waived | evidence=https://example.test/pr/70#discussion_r1 | waiver=https://example.test/pr/70#issuecomment-1
      -->
      <!-- priority-finding-dispositions v1
      head_sha: #{final_head_sha}
      finding: url=https://example.test/review/fixed | severity=P2 | disposition=fixed | evidence=https://example.test/pr/70#discussion_r2
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "WAIVED", data.fetch("overall_verdict")
    assert_equal "WAIVED", priority.fetch("verdict")
    assert_equal 2, priority.fetch("marker_count")
    assert_equal 2, priority.fetch("findings").length
  end

  def test_expected_final_head_normalizes_hex_case
    uppercase_head_sha = "ABCDEFABCDEFABCDEFABCDEFABCDEFABCDEFABCD"
    lowercase_head_sha = uppercase_head_sha.downcase
    data = run_replay(<<~MARKDOWN, expected_head_sha: uppercase_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{lowercase_head_sha}
      tested_at: PR #70 head #{uppercase_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal lowercase_head_sha, data.fetch("qa_evidence").fetch("expected_head_sha")
  end

  def test_expected_final_head_accepts_audited_range_ending_at_expected_head
    base_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: audited range #{base_sha}..#{final_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_expected_final_head_rejects_audited_range_continuing_past_expected_head
    final_head_sha = "2222222222222222222222222222222222222222"
    later_head_sha = "3333333333333333333333333333333333333333"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{final_head_sha}
      tested_at: audited range #{final_head_sha}..#{later_head_sha}
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: closeout replay
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "tested_at.head_sha"
  end

  def test_expected_final_head_accepts_current_not_applicable_qa
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: no
      status: not_applicable
      head_sha: #{final_head_sha}
      tested_at: PR #70 head #{final_head_sha}; QA not required for documentation-only change
      scope: documentation-only batch
      automated_checks: not applicable
      manual_checks: not applicable
      findings: none
      release_blocking: not_applicable
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    assert_equal "NOT_APPLICABLE", data.fetch("overall_verdict")
    assert_equal "NOT_APPLICABLE", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_expected_final_head_rejects_stale_not_applicable_qa
    stale_head_sha = "1111111111111111111111111111111111111111"
    final_head_sha = "2222222222222222222222222222222222222222"
    data = run_replay(<<~MARKDOWN, expected_head_sha: final_head_sha)
      <!-- qa-evidence v1
      required: no
      status: not_applicable
      head_sha: #{stale_head_sha}
      tested_at: PR #70 head #{stale_head_sha}; QA not required for documentation-only change
      scope: documentation-only batch
      automated_checks: not applicable
      manual_checks: not applicable
      findings: none
      release_blocking: not_applicable
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "head_sha"
    assert_includes qa.fetch("missing"), "tested_at.head_sha"
  end

  def test_expected_final_head_must_be_a_full_sha
    Tempfile.create("closeout-evidence") do |file|
      file.write("<!-- qa-evidence v1 -->")
      file.flush
      out, status = Open3.capture2e("ruby", SCRIPT, "--expected-head-sha", "abc123", file.path)

      refute status.success?, out
      assert_includes out, "must be a full 40-character hex SHA"
    end
  end

  def test_missing_markers_are_unknown
    data = run_replay("### QA Evidence\n\n- QA lane: missing marker\n")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("qa_evidence").fetch("verdict")
    assert_equal "NOT_APPLICABLE", data.fetch("priority_finding_dispositions").fetch("verdict")
  end

  def test_valid_qa_and_priority_markers_are_satisfied
    data = run_replay(<<~MARKDOWN)
      ### QA Evidence

      - QA lane: qa/evidence-gates

      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md, skills/pr-batch
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->

      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | evidence=https://example.test/pr/123#discussion_r1
      finding: url=https://example.test/review/2 | severity=Must-Fix | disposition=fixed | evidence=https://example.test/pr/123#discussion_r2
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal "SATISFIED", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_equal 2, data.fetch("priority_finding_dispositions").fetch("findings").length
  end

  def test_qa_marker_without_head_sha_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("qa_evidence").fetch("verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "head_sha"
  end

  def test_historical_not_required_qa_marker_accepts_legacy_head_placeholder
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: no
      status: not_applicable
      head_sha: not_applicable
      tested_at: no PR created
      scope: issue disposition only
      automated_checks: not applicable
      manual_checks: not applicable
      findings: none
      release_blocking: not_applicable
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    assert_equal "NOT_APPLICABLE", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_priority_marker_with_abbreviated_head_sha_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: abc123
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | evidence=https://example.test/pr/123#discussion_r1
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_includes data.fetch("priority_finding_dispositions").fetch("missing"), "head_sha"
  end

  def test_p3_priority_follow_up_is_satisfied
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/3 | severity=P3 | disposition=deferred_with_issue | evidence=https://example.test/issues/123
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("priority_finding_dispositions").fetch("verdict")
  end

  def test_waived_qa_marker_preserves_waived_overall
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: waived
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: waived by maintainer
      release_blocking: waived
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "WAIVED", data.fetch("overall_verdict")
    assert_equal "WAIVED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal "NOT_APPLICABLE", data.fetch("priority_finding_dispositions").fetch("verdict")
  end

  def test_waived_priority_marker_preserves_waived_overall
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->

      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/2 | severity=Must-Fix | disposition=waived | evidence=https://example.test/pr/123#discussion_r2 | waiver=https://example.test/pr/123#issuecomment-1
      -->
    MARKDOWN

    assert_equal "WAIVED", data.fetch("overall_verdict")
    assert_equal "WAIVED", data.fetch("priority_finding_dispositions").fetch("verdict")
  end

  def test_valid_qa_marker_without_priority_marker_is_satisfied
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("overall_verdict")
    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal "NOT_APPLICABLE", data.fetch("priority_finding_dispositions").fetch("verdict")
  end

  def test_required_qa_marker_cannot_be_not_applicable
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: not_applicable
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: not_applicable
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("qa_evidence").fetch("verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "status"
  end

  def test_incomplete_qa_marker_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("qa_evidence").fetch("verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "manual_checks"
    assert_includes data.fetch("qa_evidence").fetch("missing"), "findings"
  end

  def test_invalid_qa_required_value_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: maybe
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_includes data.fetch("qa_evidence").fetch("missing"), "required"
  end

  def test_blocked_qa_maps_to_blocked_overall
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: blocked
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: release blocker found
      release_blocking: blocked
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "BLOCKED", data.fetch("overall_verdict")
    assert_equal "BLOCKED", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_later_blocked_qa_marker_blocks_aggregate
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->

      <!-- qa-evidence v1
      required: yes
      status: blocked
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/post-merge-audit.md
      automated_checks: bin/validate
      manual_checks: replay case failed
      findings: selected CI still pending
      release_blocking: blocked
      process_gap_disposition: schema
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "BLOCKED", data.fetch("overall_verdict")
    assert_equal "BLOCKED", qa.fetch("verdict")
    assert_equal 2, qa.fetch("marker_count")
    assert_equal "BLOCKED", qa.fetch("markers").last.fetch("verdict")
  end

  def test_priority_marker_without_dispositions_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/1 | severity=P1 | evidence=https://example.test/pr/123#discussion_r1
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_includes data.fetch("priority_finding_dispositions").fetch("missing"), "finding[0].disposition"
  end

  def test_waived_priority_marker_without_waiver_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/1 | severity=P1 | disposition=waived | evidence=https://example.test/pr/123#discussion_r1
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_includes data.fetch("priority_finding_dispositions").fetch("missing"), "finding[0].waiver"
  end

  def test_priority_marker_with_invalid_severity_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/1 | severity=Optional | disposition=fixed | evidence=https://example.test/pr/123#discussion_r1
      -->
    MARKDOWN

    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", data.fetch("priority_finding_dispositions").fetch("verdict")
    assert_includes data.fetch("priority_finding_dispositions").fetch("missing"), "finding[0].severity"
  end

  def test_later_invalid_priority_marker_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head abc123
      scope: workflows/pr-processing.md
      automated_checks: bin/validate
      manual_checks: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->

      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | evidence=https://example.test/pr/123#discussion_r1
      -->

      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      finding: url=https://example.test/review/2 | severity=Optional | disposition=fixed | evidence=https://example.test/pr/123#discussion_r2
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", data.fetch("overall_verdict")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_equal 2, priority.fetch("marker_count")
    assert_includes priority.fetch("missing"), "marker[1].finding[0].severity"
  end

  def test_duplicate_priority_scalar_key_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 1111111111111111111111111111111111111111
      head_sha: 2222222222222222222222222222222222222222
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | evidence=https://example.test/pr/123#discussion_r1
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_equal ["duplicate scalar key: head_sha"], priority.fetch("errors")
  end

  def test_duplicate_priority_finding_key_is_unknown
    data = run_replay(<<~MARKDOWN)
      <!-- priority-finding-dispositions v1
      head_sha: 2222222222222222222222222222222222222222
      finding: url=https://example.test/review/1 | severity=P1 | disposition=fixed | disposition=waived | evidence=https://example.test/pr/123#discussion_r1 | waiver=https://example.test/pr/123#issuecomment-1
      -->
    MARKDOWN

    priority = data.fetch("priority_finding_dispositions")
    assert_equal "UNKNOWN", priority.fetch("verdict")
    assert_equal ["finding[0].duplicate key: disposition"], priority.fetch("errors")
  end
end
