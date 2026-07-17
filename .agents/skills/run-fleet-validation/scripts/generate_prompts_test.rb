#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "generate_prompts"

class FleetValidationGeneratorTest < Minitest::Test
  MANIFEST = File.expand_path("../../../../internal/contributor-info/demo-fleet.yml", __dir__)

  def build_generator(**overrides)
    defaults = {
      manifest_path: MANIFEST,
      prompt_count: 6,
      machines: %w[local m1],
      release_selector: "latest RC or beta",
      pack_id: "fleet-test-pack"
    }
    FleetValidation::Generator.new(**defaults.merge(overrides))
  end

  def test_balances_six_prompts_across_two_machines
    generator = build_generator

    assert_equal 6, generator.assignments.length
    assert(generator.assignments.all? { |lane| lane.fetch(:targets).length <= 2 })
    machine_counts = generator.assignments.map { |lane| lane.fetch(:machine) }.tally

    assert_equal({ "local" => 3, "m1" => 3 }, machine_counts)
  end

  def test_assigns_every_hard_gate_and_core_gate_once
    generator = build_generator
    assigned_names = generator.assignments.flat_map do |lane|
      lane.fetch(:targets).map { |target| target.fetch("name") }
    end
    manifest = YAML.safe_load_file(MANIFEST, aliases: false)
    expected_names = manifest.fetch("repos").filter_map do |repo|
      repo.fetch("name") if repo["tier"] == "hard_gate"
    end
    expected_names << "react_on_rails generator/install smoke"

    assert_equal expected_names.sort, assigned_names.sort
    assert_equal assigned_names.length, assigned_names.uniq.length
  end

  def test_generated_prompts_are_dynamic_and_require_bounded_subagents
    pack = build_generator.render_pack

    assert_includes pack, "latest RC or beta"
    assert_includes pack, "Spawn one read-only evidence subagent"
    assert_match(/Child\s+agents must not spawn more agents/, pack)
    assert_includes pack, "Do not select a candidate independently"
    assert_includes pack, "independently released `react-on-rails-rsc`"
    assert_includes pack, "the claim is the"
    assert_includes pack,
                    "fallback_claim_target_template: " \
                    "adhoc:fleet-RESOLVED_TAG-shakacode-react-on-rails-demo-flagship"
    assert_includes pack, "fallback_claim_repo: shakacode/react_on_rails"
    assert_includes pack, "adhoc:fleet-snapshot-RESOLVED_TAG"
    assert_includes pack, "Search the open `Release gate: react_on_rails X.Y.Z`"
    assert_includes pack, "workflow=cpflow-review-app.yml, status_check=cpflow/review-app"
    assert_includes pack, "one execution subagent for the assigned monorepo generator/install gate"
    assert_includes pack, "(cd react_on_rails && bundle exec rspec spec/react_on_rails/generators)"
    assert_includes pack, "verify: true"
  end

  def test_rejects_machine_names_that_collide_as_paths
    error = assert_raises(FleetValidation::ManifestError) do
      build_generator(machines: ["M 1", "m-1"])
    end

    assert_equal "machine names must have unique path slugs", error.message
  end

  def test_writes_machine_directories_and_index
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)

      assert File.exist?(File.join(directory, "INDEX.md"))
      assert_equal 3, Dir.glob(File.join(directory, "local", "*.md")).length
      assert_equal 3, Dir.glob(File.join(directory, "m1", "*.md")).length
    end
  end

  def test_index_describes_an_uneven_machine_allocation_as_a_maximum
    Dir.mktmpdir do |directory|
      build_generator(prompt_count: 5).write_pack(directory)
      index = File.read(File.join(directory, "INDEX.md"))

      assert_includes index, "runs at most\n3 prompts on one machine"
      refute_includes index, "3 prompts per machine"
    end
  end

  def test_removes_stale_lane_files_when_regenerating_an_output_directory
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      build_generator(prompt_count: 4, machines: ["local"], pack_id: "replacement-pack").write_pack(directory)

      lane_files = Dir.glob(File.join(directory, "*", "*-fleet-lane.md"))

      assert_equal 4, lane_files.length
      assert_empty Dir.glob(File.join(directory, "m1", "*-fleet-lane.md"))
      assert(lane_files.all? { |path| File.read(path).include?("replacement-pack") })
    end
  end

  def test_rejects_prompt_count_that_exceeds_two_targets_per_lane
    error = assert_raises(FleetValidation::ManifestError) do
      build_generator(prompt_count: 3)
    end

    assert_equal "--prompts must be at least 4 to keep at most two targets per lane", error.message
  end

  def test_uses_stable_target_evidence_ids
    pack = build_generator.render_pack

    assert_includes pack, "shakacode-react-on-rails-demo-flagship"
    assert_includes pack, "fleet-validation:<resolved-tag>:<stable-target-id>"
  end

  def test_rejects_unsupported_schema
    Dir.mktmpdir do |directory|
      manifest = File.join(directory, "fleet.yml")
      File.write(manifest, "schema_version: 2\nrepos: []\n")

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path: manifest)
      end
      assert_equal "schema_version must be 1", error.message
    end
  end

  def test_rejects_a_non_mapping_manifest
    Dir.mktmpdir do |directory|
      manifest = File.join(directory, "fleet.yml")
      File.write(manifest, "- repo\n")

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path: manifest)
      end
      assert_equal "manifest root must be a mapping", error.message
    end
  end

  def test_rejects_colliding_stable_target_ids
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      hard_gates = manifest.fetch("repos").select { |repo| repo["tier"] == "hard_gate" }
      hard_gates[0]["name"] = "owner/foo.bar"
      hard_gates[1]["name"] = "owner/foo-bar"
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "target names must have unique stable IDs: owner-foo-bar", error.message
    end
  end

  def test_pinned_release_ignores_newer_tracker_candidates
    pack = build_generator(release_selector: "v17.0.0.rc.12").render_pack

    assert_match(/Newer\s+candidate entries are context and must not override the pinned selector/, pack)
    refute_includes pack, "use its newest explicit RC section"
  end

  def test_dynamic_leader_resolves_the_release_before_selecting_a_tracker
    prompt = build_generator.render_pack.match(/## Prompt 1.*?```text\n(.*?)```/m).captures.first

    assert_operator prompt.index("derive the release line"), :<, prompt.index("Find the open `Release gate")
  end
end
