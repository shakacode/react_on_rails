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

  def test_every_explicit_exclusion_has_a_reviewed_reason
    refute_empty AgentWorkflowDriftManifest::EXCLUSIONS
    AgentWorkflowDriftManifest::EXCLUSIONS.each_value { |reason| refute_empty reason.strip }
  end

  private

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
