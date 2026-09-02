#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"
require "timeout"
require "minitest/autorun"

SCRIPT = File.expand_path("closeout-evidence-replay", __dir__)

class CloseoutEvidenceReplayTest < Minitest::Test
  def run_replay(body, expected_head_sha: nil, require_priority_dispositions: false, require_visual_evidence_v2: false)
    Tempfile.create("closeout-evidence") do |file|
      file.write(body)
      file.flush
      command = ["ruby", SCRIPT]
      command.concat(["--expected-head-sha", expected_head_sha]) if expected_head_sha
      command << "--require-priority-dispositions" if require_priority_dispositions
      command << "--require-visual-evidence-v2" if require_visual_evidence_v2
      command << file.path
      out, status = Open3.capture2e(*command)
      assert status.success?, out
      JSON.parse(out)
    end
  end

  def v2_marker(overrides = {})
    fields = {
      "required" => "yes",
      "status" => "satisfied",
      "head_sha" => "1111111111111111111111111111111111111111",
      "tested_at" => "PR #123 head 1111111111111111111111111111111111111111",
      "scope" => "current UI change",
      "automated_checks" => "bin/validate",
      "manual_checks" => "browser path",
      "user_visible_ui_change" => "yes",
      "visual_evidence_destination" => "github_pr",
      "visual_evidence" => "durable: before and after https://github.com/example/repo/pull/123#visual",
      "paint_check" => "passed: rendered target inspected",
      "interaction_change" => "no",
      "interaction_evidence" => "not applicable: no interaction behavior changed",
      "visual_fix" => "no",
      "negative_control" => "not applicable: no visual fix",
      "performance_impact" => "not_applicable",
      "performance_evidence" => "not applicable: no rendered-page, asset-delivery, or bundle impact",
      "findings" => "none",
      "release_blocking" => "clear",
      "process_gap_disposition" => "checklist+replay"
    }.merge(overrides.transform_keys(&:to_s))
    body = fields.map { |key, value| "#{key}: #{value}" }.join("\n")
    "<!-- qa-evidence v2\n#{body}\n-->\n"
  end

  def v1_marker(head_sha:, status: "satisfied", release_blocking: "clear")
    <<~MARKDOWN
      <!-- qa-evidence v1
      required: yes
      status: #{status}
      head_sha: #{head_sha}
      tested_at: PR #123 head #{head_sha}
      scope: legacy UI evidence
      automated_checks: bin/validate
      manual_checks: browser path
      findings: none
      release_blocking: #{release_blocking}
      process_gap_disposition: schema
      -->
    MARKDOWN
  end

  def test_help_describes_required_priority_evidence
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")

    assert status.success?, out
    assert_includes out, "Fail when priority evidence is missing or explicitly not_applicable"
    assert_includes out, "Fail when current UI evidence lacks the durable visual-evidence v2 contract"
  end

  def test_strict_visual_gate_requires_expected_head_sha
    out, status = Open3.capture2e(
      "ruby",
      SCRIPT,
      "--require-visual-evidence-v2",
      "-",
      stdin_data: v2_marker
    )

    assert_equal 64, status.exitstatus
    assert_includes out, "--require-visual-evidence-v2 requires --expected-head-sha"
  end

  def test_historical_v1_remains_replayable_without_visual_fields
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: historical UI change
      automated_checks: bin/validate
      manual_checks: browser smoke
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
    assert_equal 1, data.fetch("qa_evidence").fetch("marker_version")
  end

  def test_current_ui_gate_rejects_v1_only_evidence
    head_sha = "1111111111111111111111111111111111111111"
    data = run_replay(<<~MARKDOWN, expected_head_sha: head_sha, require_visual_evidence_v2: true)
      <!-- qa-evidence v1
      required: yes
      status: satisfied
      head_sha: #{head_sha}
      tested_at: PR #123 head #{head_sha}
      scope: current UI change
      automated_checks: bin/validate
      manual_checks: screenshots captured locally
      findings: none
      release_blocking: clear
      process_gap_disposition: schema
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "qa-evidence v2 marker required for current user-visible UI evidence"
  end

  def test_strict_v2_gate_rejects_marker_name_suffixes
    head_sha = "1111111111111111111111111111111111111111"

    %w[v20 v2draft].each do |version|
      body = v2_marker.sub("qa-evidence v2", "qa-evidence #{version}")
      qa = run_replay(
        body,
        expected_head_sha: head_sha,
        require_visual_evidence_v2: true
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), version
      assert_includes qa.fetch("missing"), "qa-evidence v2 marker required for current user-visible UI evidence", version
    end
  end

  def test_v2_accepts_durable_tracker_visual_clip_negative_control_and_metric_evidence
    head_sha = "1111111111111111111111111111111111111111"
    data = run_replay(<<~MARKDOWN, expected_head_sha: head_sha, require_visual_evidence_v2: true)
      <!-- qa-evidence v2
      required: yes
      status: satisfied
      head_sha: #{head_sha}
      tested_at: PR #123 head #{head_sha}
      scope: map marker geometry and hover state
      automated_checks: bin/validate
      manual_checks: browser geometry and hover path
      user_visible_ui_change: yes
      visual_evidence_destination: linked_tracker
      visual_evidence: durable: before and after composite https://linear.app/example/issue/UI-123#attachment
      paint_check: passed: rendered target inspected
      interaction_change: yes
      interaction_evidence: clip: https://linear.app/example/issue/UI-123#hover-recording
      visual_fix: yes
      negative_control: observed_failure: unfixed bundle failed assertion; expected 0 within 1 of 104
      performance_impact: measured_metric
      performance_evidence: repo_seam: source=bin/perf-report; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "SATISFIED", qa.fetch("verdict")
    assert_equal 2, qa.fetch("marker_version")
    assert_empty qa.fetch("missing")
  end

  def test_v2_accepts_measured_interaction_substitute_and_hygiene_claim
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v2
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: map marker geometry and hover state
      automated_checks: bin/validate
      manual_checks: browser geometry and hover path
      user_visible_ui_change: yes
      visual_evidence_destination: github_pr
      visual_evidence: durable: before and after images https://github.com/example/repo/pull/123#issue-attachment
      paint_check: passed: painted marker and map tiles inspected
      interaction_change: yes
      interaction_evidence: measured_substitute: before_value=52px; after_value=0px; tolerance=1px
      visual_fix: yes
      negative_control: observed_failure: unfixed bundle failed the geometry assertion
      performance_impact: bundle_hygiene
      performance_evidence: repo_seam: source=bin/bundle-report; baseline_value=120kB; candidate_value=121kB
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "SATISFIED", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_v2_github_only_prepared_artifacts_are_blocked_until_human_attachment
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v2
      required: yes
      status: blocked
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: current UI change
      automated_checks: bin/validate
      manual_checks: browser path complete; durable attachment pending
      user_visible_ui_change: yes
      visual_evidence_destination: human_attachment_pending
      visual_evidence: blocked: human attachment required; prepared local artifacts: /tmp/before.png /tmp/after.png
      paint_check: passed: rendered screenshots inspected
      interaction_change: no
      interaction_evidence: not applicable: no interaction behavior changed
      visual_fix: yes
      negative_control: observed_failure: unfixed implementation failed the visual assertion
      performance_impact: not_applicable
      performance_evidence: not applicable: no rendered-page, asset-delivery, or bundle impact
      findings: blocked on human attachment
      release_blocking: blocked
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    assert_equal "BLOCKED", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_v2_rejects_local_paths_as_durable_visual_or_interaction_evidence
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v2
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: current UI change
      automated_checks: bin/validate
      manual_checks: captured locally
      user_visible_ui_change: yes
      visual_evidence_destination: github_pr
      visual_evidence: durable: before /tmp/before.png and after /tmp/after.png
      paint_check: passed: rendered screenshots inspected
      interaction_change: yes
      interaction_evidence: clip: /tmp/hover.mov
      visual_fix: yes
      negative_control: observed_failure: unfixed implementation failed the visual assertion
      performance_impact: not_applicable
      performance_evidence: not applicable: no rendered-page, asset-delivery, or bundle impact
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence.url"
    assert_includes qa.fetch("missing"), "interaction_evidence"
  end

  def test_v2_rejects_blank_paint_check_unreasoned_na_and_missing_negative_control
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v2
      required: yes
      status: satisfied
      head_sha: 1111111111111111111111111111111111111111
      tested_at: PR #123 head 1111111111111111111111111111111111111111
      scope: current UI fix
      automated_checks: bin/validate
      manual_checks: browser path
      user_visible_ui_change: yes
      visual_evidence_destination: repo_artifact_store
      visual_evidence: durable: before and after https://artifacts.example.test/ui-123
      paint_check: passed: blank screenshot
      interaction_change: no
      interaction_evidence: not applicable
      visual_fix: yes
      negative_control: captured locally
      performance_impact: not_applicable
      performance_evidence: not applicable
      findings: none
      release_blocking: clear
      process_gap_disposition: checklist+replay
      -->
    MARKDOWN

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    %w[paint_check interaction_evidence negative_control performance_evidence].each do |field|
      assert_includes qa.fetch("missing"), field
    end
  end

  def test_v2_non_ui_change_requires_reasoned_not_applicable_values
    data = run_replay(<<~MARKDOWN)
      <!-- qa-evidence v2
      required: no
      status: not_applicable
      head_sha: 1111111111111111111111111111111111111111
      tested_at: repository head 1111111111111111111111111111111111111111
      scope: documentation-only change
      automated_checks: bin/validate
      manual_checks: not applicable: no runtime behavior
      user_visible_ui_change: no
      visual_evidence_destination: not_applicable
      visual_evidence: not applicable: no user-visible UI change
      paint_check: not applicable: no rendered target
      interaction_change: no
      interaction_evidence: not applicable: no interaction change
      visual_fix: no
      negative_control: not applicable: no visual fix
      performance_impact: not_applicable
      performance_evidence: not applicable: no rendered-page, asset-delivery, or bundle impact
      findings: none
      release_blocking: not_applicable
      process_gap_disposition: not applicable
      -->
    MARKDOWN

    assert_equal "NOT_APPLICABLE", data.fetch("qa_evidence").fetch("verdict")
  end

  def test_v2_non_ui_change_allows_required_bundle_performance_evidence
    qa = run_replay(
      v2_marker(
        "user_visible_ui_change" => "no",
        "visual_evidence_destination" => "not_applicable",
        "visual_evidence" => "not applicable: no user-visible UI change",
        "paint_check" => "not applicable: no rendered target",
        "interaction_change" => "no",
        "interaction_evidence" => "not applicable: no interaction change",
        "visual_fix" => "no",
        "negative_control" => "not applicable: no visual fix",
        "performance_impact" => "bundle_hygiene",
        "performance_evidence" => "repo_seam: source=bin/bundle-report; baseline_value=100KB; candidate_value=90KB"
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
  end

  def test_v2_non_ui_change_rejects_legacy_head_placeholder_without_expected_head
    body = v2_marker(
      "required" => "no",
      "status" => "not_applicable",
      "head_sha" => "not_applicable",
      "tested_at" => "no PR created",
      "user_visible_ui_change" => "no",
      "visual_evidence_destination" => "not_applicable",
      "visual_evidence" => "not applicable: no user-visible UI change",
      "paint_check" => "not applicable: no rendered target",
      "interaction_change" => "no",
      "interaction_evidence" => "not applicable: no interaction change",
      "visual_fix" => "no",
      "negative_control" => "not applicable: no visual fix",
      "performance_impact" => "not_applicable",
      "performance_evidence" => "not applicable: no rendered-page impact",
      "release_blocking" => "not_applicable"
    )

    qa = run_replay(body).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "head_sha"
    assert_includes qa.fetch("missing"), "tested_at.head_sha"
  end

  def test_v2_rejects_disallowed_local_and_failed_capture_tokens_even_with_https
    bad_evidence = {
      "absolute path" => "durable: before /tmp/before.png and after https://github.com/example/repo/pull/123#visual",
      "Windows path" => "durable: before C:\\tmp\\before.png and after https://github.com/example/repo/pull/123#visual",
      "file URL" => "durable: before file:///tmp/before.png and after https://github.com/example/repo/pull/123#visual",
      "captured locally" => "durable: before captured locally and after https://github.com/example/repo/pull/123#visual",
      "blank screenshot" => "durable: before screenshot was blank and after rendered https://github.com/example/repo/pull/123#visual",
      "unpainted page" => "durable: before page was unpainted and after rendered https://github.com/example/repo/pull/123#visual"
    }

    bad_evidence.each do |label, evidence|
      data = run_replay(v2_marker("visual_evidence" => evidence))
      qa = data.fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), label
      assert_includes qa.fetch("missing"), "visual_evidence.local_reference", label
    end
  end

  def test_v2_allows_blank_as_a_legitimate_before_state_description
    evidence = "durable: before blank search results and after populated results https://github.com/example/repo/pull/123#visual"
    qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
    refute_includes qa.fetch("missing"), "visual_evidence.local_reference"
  end

  def test_v2_rejects_ephemeral_non_https_artifact_schemes_even_with_https
    schemes = [
      "blob:https://example.test/transient-id",
      "data:image/png;base64,AAAA",
      "filesystem:https://example.test/temporary/before.png",
      "http://example.test/before.png",
      "ftp://example.test/before.png",
      "mediastream:transient-id"
    ]

    schemes.each do |artifact|
      evidence = "durable: before #{artifact} and after https://github.com/example/repo/pull/123#visual"
      qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), artifact
      assert_includes qa.fetch("missing"), "visual_evidence.local_reference", artifact
    end
  end

  def test_v2_rejects_relative_local_artifact_tokens_even_with_https
    bad_tokens = [
      "./before.png",
      "../before.png",
      "~/before.png",
      "screenshots\\before.png",
      ".\\before.png",
      "..\\before.png",
      "C:before.png",
      "C:before",
      "assets/before.png",
      "before.png",
      "local-screenshot.webp",
      "local-screenshot.heic",
      "\\\\server\\share\\before"
    ]

    bad_tokens.each do |token|
      evidence = "durable: before #{token} and after https://github.com/example/repo/pull/123#visual"
      qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), token
      assert_includes qa.fetch("missing"), "visual_evidence.local_reference", token
    end
  end

  def test_v2_local_reference_detection_handles_pathological_separator_runs
    pathological_tokens = {
      "unterminated backslash path" => ["segment\\" * 25_000, "SATISFIED"],
      "long slash path" => ["segment/" * 25_000, "UNKNOWN"]
    }

    Timeout.timeout(3) do
      pathological_tokens.each do |label, (token, expected_verdict)|
        evidence = "durable: before #{token} and after https://github.com/example/repo/pull/123#visual"
        qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

        assert_equal expected_verdict, qa.fetch("verdict"), label
        assert_includes qa.fetch("missing"), "visual_evidence.local_reference", label if expected_verdict == "UNKNOWN"
      end
    end
  end

  def test_v2_does_not_treat_https_path_component_as_a_local_artifact
    evidence = "durable: before and after https://github.com/example/repo/blob/main/screenshots/before.png"
    qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
    refute_includes qa.fetch("missing"), "visual_evidence.local_reference"
  end

  def test_v2_allows_documented_and_common_slash_separated_labels
    %w[before/after baseline/candidate pass/fail on/off yes/no].each do |label|
      evidence = "durable: before and after #{label} composite https://github.com/example/repo/pull/123#visual"
      qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

      assert_equal "SATISFIED", qa.fetch("verdict"), label
      refute_includes qa.fetch("missing"), "visual_evidence.local_reference", label
    end
  end

  def test_v2_github_destination_requires_a_github_url
    data = run_replay(
      v2_marker(
        "visual_evidence" => "durable: before and after https://artifacts.example.test/ui-123"
      )
    )

    qa = data.fetch("qa_evidence")
    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence.github_url"
  end

  def test_v2_github_destination_rejects_bare_github_host
    qa = run_replay(
      v2_marker(
        "visual_evidence" => "durable: before and after https://github.com"
      )
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence.github_url"
  end

  def test_v2_github_destination_rejects_github_url_nested_in_tracker_query
    nested = "https://tracker.example.test/artifact?next=https://github.com/example/repo/pull/123#visual"
    evidence = "durable: before and after #{nested}"
    qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence.github_url"
  end

  def test_v2_rejects_https_evidence_without_a_valid_host
    %w[
      https://;
      https://example.test:bad/path
      https://localhost/artifact
      https://127.0.0.1/artifact
      https://0.0.0.0/artifact
      https://private-user-images.githubusercontent.com/1/clip.mp4?jwt=signed
    ].each do |url|
      %w[linked_tracker repo_artifact_store].each do |destination|
        qa = run_replay(
          v2_marker(
            "visual_evidence_destination" => destination,
            "visual_evidence" => "durable: before and after #{url}"
          )
        ).fetch("qa_evidence")

        assert_equal "UNKNOWN", qa.fetch("verdict"), "#{destination}: #{url}"
        assert_includes qa.fetch("missing"), "visual_evidence.url", "#{destination}: #{url}"
      end
    end
  end

  def test_v2_rejects_invalid_artifact_urls_even_beside_a_valid_url
    expiring_url = "https://private-user-images.githubusercontent.com/1/before.png?jwt=signed"
    valid_url = "https://github.com/example/repo/pull/123#after"
    visual = run_replay(
      v2_marker(
        "visual_evidence" => "durable: before #{expiring_url} after #{valid_url}"
      )
    ).fetch("qa_evidence")
    interaction = run_replay(
      v2_marker(
        "interaction_change" => "yes",
        "interaction_evidence" => "clip: #{expiring_url} #{valid_url}"
      )
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", visual.fetch("verdict")
    assert_includes visual.fetch("missing"), "visual_evidence.url"
    assert_equal "UNKNOWN", interaction.fetch("verdict")
    assert_includes interaction.fetch("missing"), "interaction_evidence"
  end

  def test_v2_github_destination_accepts_current_and_legacy_attachment_hosts
    hosts = %w[
      github.com/example/repo/pull/123#visual
      user-images.githubusercontent.com/123/before.png
    ]

    hosts.each do |host_and_path|
      evidence = "durable: before and after https://#{host_and_path}"
      qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

      assert_equal "SATISFIED", qa.fetch("verdict"), host_and_path
    end
  end

  def test_v2_github_destination_rejects_expiring_private_attachment_host
    evidence = "durable: before and after https://private-user-images.githubusercontent.com/123/after.png?jwt=signed"
    qa = run_replay(v2_marker("visual_evidence" => evidence)).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence.github_url"
  end

  def test_v2_rejects_negated_paint_claims
    invalid_claims = [
      "passed: target was not painted",
      "passed: target did not render",
      "passed: browser failed to paint target",
      "passed: browser failed to render target",
      "passed: target was never rendered",
      "passed: target rendered unsuccessfully",
      "passed: target was unsuccessfully painted",
      "passed: target rendered but paint failed"
    ]

    invalid_claims.each do |paint_check|
      qa = run_replay(v2_marker("paint_check" => paint_check)).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), paint_check
      assert_includes qa.fetch("missing"), "paint_check", paint_check
    end
  end

  def test_v2_interaction_classifier_is_fail_closed
    invalid_cases = [
      {
        "interaction_change" => "yes",
        "interaction_evidence" => "not applicable: recorder unavailable"
      },
      {
        "interaction_change" => "no",
        "interaction_evidence" => "clip: https://github.com/example/repo/pull/123#clip"
      },
      {
        "interaction_change" => "yes",
        "interaction_evidence" => "clip: https://github.com/example/repo/pull/123#clip /tmp/local.mov"
      },
      {
        "interaction_change" => "yes",
        "interaction_evidence" => "clip: https://github.com/example/repo/pull/123#clip hover.mov"
      },
      {
        "interaction_change" => "yes",
        "interaction_evidence" => "clip: https://github.com/example/repo/pull/123#clip .\\hover.mov"
      }
    ]

    invalid_cases.each do |overrides|
      qa = run_replay(v2_marker(overrides)).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict")
      assert_includes qa.fetch("missing"), "interaction_evidence"
    end
  end

  def test_v2_measured_interaction_substitute_requires_exact_values_units_and_tolerance
    invalid_values = [
      "measured_substitute: before 52px; after 0px",
      "measured_substitute: before_value=52px; after_value=0px",
      "measured_substitute: before_value=52; after_value=0; tolerance=1",
      "measured_substitute: before_value=52px; after_value=0px; tolerance=1ms",
      "measured_substitute: https://example.test/run/52/0/1",
      "measured_substitute: before_value=https://example.test/52px; after_value=0px; tolerance=1px"
    ]

    invalid_values.each do |evidence|
      qa = run_replay(
        v2_marker(
          "interaction_change" => "yes",
          "interaction_evidence" => evidence
        )
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), evidence
      assert_includes qa.fetch("missing"), "interaction_evidence", evidence
    end
  end

  def test_v2_measured_interaction_substitute_accepts_deterministic_alias_pair
    evidence = "measured_substitute: baseline_value=52px; candidate_value=0px; tolerance=1px"
    qa = run_replay(
      v2_marker(
        "interaction_change" => "yes",
        "interaction_evidence" => evidence
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
  end

  def test_v2_visual_fix_classifier_is_fail_closed
    invalid_cases = [
      {
        "visual_fix" => "yes",
        "negative_control" => "not applicable: unfixed build unavailable"
      },
      {
        "visual_fix" => "no",
        "negative_control" => "observed_failure: unfixed implementation failed assertion"
      }
    ]

    invalid_cases.each do |overrides|
      qa = run_replay(v2_marker(overrides)).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict")
      assert_includes qa.fetch("missing"), "negative_control"
    end
  end

  def test_v2_negative_control_rejects_negated_failure_and_passing_claims
    invalid_claims = [
      "observed_failure: assertion did not fail",
      "observed_failure: no failure was observed",
      "observed_failure: no error occurred",
      "observed_failure: assert did not error",
      "observed_failure: assertion never failed",
      "observed_failure: completed without mismatch",
      "observed_failure: assertion no longer fails",
      "observed_failure: assertion stopped failing",
      "observed_failure: assertion fails no more",
      "observed_failure: assertion passed",
      "observed_failure: negative control passes",
      "observed_failure: run succeeded",
      "observed_failure: assertion was successful",
      "observed_failure: expected output matched",
      "observed_failure: everything was okay"
    ]

    invalid_claims.each do |negative_control|
      qa = run_replay(
        v2_marker(
          "visual_fix" => "yes",
          "negative_control" => negative_control
        )
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), negative_control
      assert_includes qa.fetch("missing"), "negative_control", negative_control
    end
  end

  def test_v2_negative_control_allows_historical_pass_word_when_outcome_failed
    evidence = "observed_failure: the control that used to pass validation now fails the assertion"
    qa = run_replay(
      v2_marker(
        "visual_fix" => "yes",
        "negative_control" => evidence
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
  end

  def test_v2_negative_control_accepts_assertion_failure_description
    evidence = "observed_failure: assertion expected 1 but got 2"
    qa = run_replay(
      v2_marker(
        "visual_fix" => "yes",
        "negative_control" => evidence
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
  end

  def test_v2_reasoned_not_applicable_rejects_unresolved_placeholders
    invalid_reasons = [
      "not applicable: UNKNOWN",
      "not applicable: unavailable",
      "not applicable: evidence missing",
      "not applicable: N/A",
      "not applicable: unmeasured",
      "not applicable: not measured",
      "not_applicable: not available"
    ]

    invalid_reasons.each do |reason|
      interaction_qa = run_replay(
        v2_marker(
          "interaction_change" => "no",
          "interaction_evidence" => reason
        )
      ).fetch("qa_evidence")
      negative_qa = run_replay(
        v2_marker(
          "visual_fix" => "no",
          "negative_control" => reason
        )
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", interaction_qa.fetch("verdict"), reason
      assert_includes interaction_qa.fetch("missing"), "interaction_evidence", reason
      assert_equal "UNKNOWN", negative_qa.fetch("verdict"), reason
      assert_includes negative_qa.fetch("missing"), "negative_control", reason
    end
  end

  def test_v2_performance_claim_requires_measured_baseline_and_candidate_values
    invalid_evidence = [
      "repo_seam: baseline unavailable; candidate 2.1s",
      "repo_seam: baseline 2.4s; candidate not measured",
      "repo_seam: baseline unknown; candidate missing",
      "repo_seam: baseline and candidate report",
      "repo_seam: candidate 2.1s only",
      "not applicable: no performance command",
      "repo_seam: report https://ci.example.test/run/120/121",
      "repo_seam: report https://ci.example.test/run?baseline_value=120kB;candidate_value=121kB",
      "repo_seam: report; baseline_value=120; candidate_value=121",
      "repo_seam: report; baseline_value=120kB; candidate_value=121ms"
    ]

    %w[bundle_hygiene measured_metric].each do |classification|
      invalid_evidence.each do |evidence|
        qa = run_replay(
          v2_marker(
            "performance_impact" => classification,
            "performance_evidence" => evidence
          )
        ).fetch("qa_evidence")

        assertion_label = "#{classification}: #{evidence}"
        assert_equal "UNKNOWN", qa.fetch("verdict"), assertion_label
        assert_includes qa.fetch("missing"), "performance_evidence", assertion_label
      end
    end
  end

  def test_v2_measured_metric_requires_named_non_size_runtime_or_user_metric
    invalid_evidence = [
      "repo_seam: source=bin/perf-report; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=bin/perf-report; metric_name=bundle_size; baseline_value=120kB; candidate_value=121kB",
      "repo_seam: source=bin/perf-report; metric_name=asset bytes; baseline_value=120kB; candidate_value=121kB",
      "repo_seam: source=bin/perf-report; metric_name=score; baseline_value=120kB; candidate_value=121kB",
      "repo_seam: source=bin/perf-report; metric_name=performance_score; baseline_value=120kB; candidate_value=121kB",
      "repo_seam: source=bin/perf-report; metric_name=LCP; metric_name=INP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=bin/perf-report; metric_name=test_count; baseline_value=100tests; candidate_value=110tests",
      "repo_seam: source=bin/perf-report; metric_name=placeholder; baseline_value=1ms; candidate_value=2ms",
      "repo_seam: source=bin/perf-report; metric_name=widgets_clicked; baseline_value=5x; candidate_value=3x",
      "repo_seam: source=bin/perf-report; metric_name=active_user_count; baseline_value=5users; candidate_value=3users",
      "repo_seam: source=bin/perf-report; metric_name=power_user_score; baseline_value=5x; candidate_value=3x"
    ]

    invalid_evidence.each do |evidence|
      qa = run_replay(
        v2_marker(
          "performance_impact" => "measured_metric",
          "performance_evidence" => evidence
        )
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), evidence
      assert_includes qa.fetch("missing"), "performance_evidence", evidence
    end
  end

  def test_v2_measured_metric_allows_byte_valued_memory_but_not_byte_valued_timing
    memory = run_replay(
      v2_marker(
        "performance_impact" => "measured_metric",
        "performance_evidence" => "repo_seam: source=bin/perf-report; metric_name=memory; baseline_value=100MB; candidate_value=90MB"
      )
    ).fetch("qa_evidence")
    timing = run_replay(
      v2_marker(
        "performance_impact" => "measured_metric",
        "performance_evidence" => "repo_seam: source=bin/perf-report; metric_name=LCP; baseline_value=100MB; candidate_value=90MB"
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", memory.fetch("verdict")
    assert_equal "UNKNOWN", timing.fetch("verdict")
    assert_includes timing.fetch("missing"), "performance_evidence"
  end

  def test_v2_bundle_hygiene_does_not_require_metric_name
    qa = run_replay(
      v2_marker(
        "performance_impact" => "bundle_hygiene",
        "performance_evidence" => "repo_seam: source=bin/bundle-report; baseline_value=120kB; candidate_value=121kB"
      )
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
  end

  def test_v2_measurements_require_exact_unit_case
    evidence = "repo_seam: source=bin/bundle-report; baseline_value=100Kb; candidate_value=90KB"
    qa = run_replay(
      v2_marker(
        "performance_impact" => "bundle_hygiene",
        "performance_evidence" => evidence
      )
    ).fetch("qa_evidence")
    substitute = run_replay(
      v2_marker(
        "interaction_change" => "yes",
        "interaction_evidence" => "measured_substitute: before_value=1ms; after_value=2MS; tolerance=1ms"
      )
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "performance_evidence"
    assert_equal "UNKNOWN", substitute.fetch("verdict")
    assert_includes substitute.fetch("missing"), "interaction_evidence"
  end

  def test_v2_bundle_hygiene_rejects_unrelated_counts_and_accepts_labeled_shape
    invalid = run_replay(
      v2_marker(
        "performance_impact" => "bundle_hygiene",
        "performance_evidence" => "repo_seam: source=bin/test-report; baseline_value=100tests; candidate_value=110tests"
      )
    ).fetch("qa_evidence")
    valid = run_replay(
      v2_marker(
        "performance_impact" => "bundle_hygiene",
        "performance_evidence" => "repo_seam: source=bin/bundle-report; metric_name=asset_count; baseline_value=10files; candidate_value=11files"
      )
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", invalid.fetch("verdict")
    assert_includes invalid.fetch("missing"), "performance_evidence"
    assert_equal "SATISFIED", valid.fetch("verdict")
  end

  def test_v2_performance_evidence_requires_named_repo_seam_source
    invalid_sources = [
      "repo_seam: metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=report; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=UNKNOWN; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=https://; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: source=http://report.example.test/run; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s",
      "repo_seam: https://ci.example.test/run?a=1;source=fake/report; source missing; metric_name=LCP; baseline_value=2.4s; candidate_value=2.1s"
    ]

    invalid_sources.each do |evidence|
      qa = run_replay(
        v2_marker(
          "performance_impact" => "measured_metric",
          "performance_evidence" => evidence
        )
      ).fetch("qa_evidence")

      assert_equal "UNKNOWN", qa.fetch("verdict"), evidence
      assert_includes qa.fetch("missing"), "performance_evidence", evidence
    end
  end

  def test_v2_not_applicable_performance_rejects_unmeasured_placeholder
    qa = run_replay(
      v2_marker(
        "performance_impact" => "not_applicable",
        "performance_evidence" => "not applicable: performance was unmeasured"
      )
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "performance_evidence"
  end

  def test_current_v2_supersedes_legacy_v1_including_same_head_blocked_v1
    head_sha = "1111111111111111111111111111111111111111"
    body = [
      v1_marker(head_sha: "0000000000000000000000000000000000000000"),
      v1_marker(head_sha: head_sha, status: "blocked", release_blocking: "blocked"),
      v2_marker
    ].join("\n")
    qa = run_replay(
      body,
      expected_head_sha: head_sha,
      require_visual_evidence_v2: true
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
    assert_equal 2, qa.fetch("marker_version")
    assert_equal 1, qa.fetch("supersedes_marker_version")
    assert_equal 1, qa.fetch("marker_count")
  end

  def test_default_replay_ignores_quoted_v2_template_beside_current_v1_evidence
    head_sha = "1111111111111111111111111111111111111111"
    quoted_v2 = v2_marker(
      "head_sha" => "<full commit SHA>",
      "tested_at" => "PR head <full commit SHA>"
    )
    qa = run_replay(
      "#{v1_marker(head_sha: head_sha)}\n#{quoted_v2}",
      expected_head_sha: head_sha
    ).fetch("qa_evidence")

    assert_equal "SATISFIED", qa.fetch("verdict")
    assert_equal 1, qa.fetch("marker_version")
  end

  def test_stale_v2_cannot_be_rescued_by_current_v1
    current_head = "1111111111111111111111111111111111111111"
    stale_head = "2222222222222222222222222222222222222222"
    stale_v2 = v2_marker(
      "head_sha" => stale_head,
      "tested_at" => "PR #123 head #{stale_head}"
    )
    qa = run_replay(
      "#{v1_marker(head_sha: current_head)}\n#{stale_v2}",
      expected_head_sha: current_head,
      require_visual_evidence_v2: true
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "head_sha"
  end

  def test_malformed_v2_cannot_be_rescued_by_current_v1
    head_sha = "1111111111111111111111111111111111111111"
    malformed_v2 = v2_marker("visual_evidence" => "captured locally")
    qa = run_replay(
      "#{v1_marker(head_sha: head_sha)}\n#{malformed_v2}",
      expected_head_sha: head_sha,
      require_visual_evidence_v2: true
    ).fetch("qa_evidence")

    assert_equal "UNKNOWN", qa.fetch("verdict")
    assert_includes qa.fetch("missing"), "visual_evidence"
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
