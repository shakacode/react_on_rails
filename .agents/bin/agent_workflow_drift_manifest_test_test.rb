# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tempfile"
require_relative "agent-workflow-drift-manifest-test"

class AgentWorkflowDriftManifestTest < Minitest::Test
  def test_safe_yaml_loader_rejects_aliases
    Tempfile.create(["agent-workflow-drift", ".yml"]) do |file|
      file.write("version: &version 1\nsource_revision: *version\nfiles: []\n")
      file.flush
      errors = []

      manifest = AgentWorkflowDriftManifest.load_manifest(file.path, errors)

      assert_empty manifest
      assert_equal 1, errors.length
      assert_match(/alias(?:es)? .*not (?:enabled|allowed)/i, errors.first)
    end
  end

  def test_inventory_requires_new_files_under_governed_prefixes
    source_files = baseline_source_files + ["skills/pr-batch/bin/future-helper"]
    errors = []

    AgentWorkflowDriftManifest.validate_inventory(
      source_files,
      baseline_mapped_sources,
      baseline_mapped_sources,
      errors
    )

    assert_includes errors, "required governed source is not mapped: skills/pr-batch/bin/future-helper"
  end

  def test_inventory_requires_every_same_path_consumer_file_to_be_mapped
    local_unmapped = "skills/pr-batch/bin/local-unmapped"
    errors = []

    AgentWorkflowDriftManifest.validate_inventory(
      baseline_source_files + [local_unmapped],
      baseline_mapped_sources + [local_unmapped],
      baseline_mapped_sources,
      errors
    )

    assert_includes errors, "same-path consumer source is not mapped: #{local_unmapped}"
  end

  def test_manifest_requires_same_path_consumer_mapping
    errors = []
    manifest = {
      "files" => [
        {
          "source" => "skills/pr-batch/bin/existing-helper",
          "consumer" => ".agents/bin/wrong-helper"
        }
      ]
    }

    AgentWorkflowDriftManifest.mapped_pairs(manifest, errors)

    assert_includes errors,
                    "manifest consumer path must match source path: " \
                    "skills/pr-batch/bin/existing-helper -> .agents/bin/wrong-helper"
  end

  def test_failure_diagnostics_are_sorted
    Tempfile.create(["agent-workflow-drift", ".yml"]) do |file|
      file.write("--- {}\n")
      file.flush
      output = StringIO.new

      result = AgentWorkflowDriftManifest.run(
        manifest_path: file.path,
        source_root: Dir.pwd,
        consumer_root: Dir.pwd,
        output:
      )

      assert_equal 1, result
      diagnostics = output.string.lines.drop(1).map(&:strip)
      assert_equal diagnostics.sort, diagnostics
    end
  end

  def test_failure_diagnostics_escape_control_bytes_before_rendering
    output = render_injected_diagnostic("malicious\e[31m\n  - FAKE_OK")

    assert_includes output, 'malicious\u{001B}[31m\n  - FAKE_OK'
    refute_includes output, "\e"
    refute_includes output, "\n  - FAKE_OK"
  end

  def test_failure_diagnostics_escape_bidi_controls_before_rendering
    output = render_injected_diagnostic("safe\u202Etxt\u2066  - FAKE_OK")

    assert_includes output, 'safe\u{202E}txt\u{2066}  - FAKE_OK'
    refute_includes output, "\u202E"
    refute_includes output, "\u2066"
  end

  def test_failure_diagnostics_escape_unicode_line_separators_before_rendering
    output = render_injected_diagnostic("safe\u2028  - FAKE_LINE\u2029  - FAKE_PARAGRAPH")

    assert_includes output, 'safe\u{2028}  - FAKE_LINE\u{2029}  - FAKE_PARAGRAPH'
    refute_includes output, "\u2028"
    refute_includes output, "\u2029"
  end

  def test_failure_diagnostics_replace_non_utf8_bytes_before_rendering
    diagnostic = "safe\xFF\n  - FAKE_OK".b.force_encoding(Encoding::UTF_8)

    output = render_injected_diagnostic(diagnostic)

    assert_predicate output, :valid_encoding?
    assert_includes output, "safe\uFFFD\\n  - FAKE_OK"
    refute_includes output.b, "\xFF".b
    refute_includes output, "\n  - FAKE_OK"
  end

  def test_pinned_git_timeout_fails_closed_with_a_sanitized_diagnostic
    revision = "a" * 40
    errors = []
    timeout_message = "Git probe timed out after 10 seconds\n  - FAKE_OK"
    timed_out_capture = lambda do |*_arguments, **_options|
      raise PrBatchGitProbeEnv::TimeoutError, timeout_message
    end

    source_files = with_stubbed_git_capture(timed_out_capture) do
      AgentWorkflowDriftManifest.pinned_source_files("/tmp/pinned-source", revision, errors)
    end

    assert_empty source_files
    assert_equal ["cannot enumerate pinned source tree #{revision}: #{timeout_message}"], errors

    output = StringIO.new
    AgentWorkflowDriftManifest.render_errors(output, errors)
    assert_includes output.string, "timed out after 10 seconds\\n  - FAKE_OK"
    refute_includes output.string, "\n  - FAKE_OK"
  end

  def test_every_explicit_exclusion_has_a_reviewed_reason
    refute_empty AgentWorkflowDriftManifest::EXCLUSIONS
    AgentWorkflowDriftManifest::EXCLUSIONS.each_value { |reason| refute_empty reason.strip }
  end

  private

  def render_injected_diagnostic(diagnostic)
    output = StringIO.new
    AgentWorkflowDriftManifest.render_errors(output, [diagnostic])
    output.string
  end

  def with_stubbed_git_capture(replacement)
    original = PrBatchGitProbeEnv.method(:capture3)
    PrBatchGitProbeEnv.define_singleton_method(:capture3, replacement)
    yield
  ensure
    PrBatchGitProbeEnv.define_singleton_method(:capture3, original)
  end

  def baseline_source_files
    @baseline_source_files ||= (
      AgentWorkflowDriftManifest::REQUIRED_EXPLICIT_PATHS +
      AgentWorkflowDriftManifest::EXCLUSIONS.keys +
      ["skills/pr-batch/bin/existing-helper"]
    ).sort
  end

  def baseline_mapped_sources
    baseline_source_files - AgentWorkflowDriftManifest::EXCLUSIONS.keys
  end
end
