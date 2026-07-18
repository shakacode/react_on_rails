#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tempfile"

ROOT = File.expand_path("../../..", __dir__)
HELPER = File.expand_path("stage-dependency-gate", __dir__)
REPLAY_FIXTURES = File.expand_path("../fixtures/stage-dependency-gate-replays.json", __dir__)
SHA_A = "1111111111111111111111111111111111111111"
SHA_B = "2222222222222222222222222222222222222222"
BASE_SHA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
PORTABLE_HELPER_CALL = '"${PR_BATCH_SKILL_DIR}/bin/stage-dependency-gate"'
REPOSITORY_RELATIVE_HELPER = "skills/pr-batch/bin/stage-dependency-gate"
HELPER_RESOLUTION_RULES = [
  "explicit environment variable",
  "the loaded skill's base directory when the host exposes it",
  "repo-local `.agents/skills/pr-batch`",
  "stop with a precise blocker"
].freeze
SINGLE_TARGET_MANIFEST_CONTRACT = "When no planner/triage handoff supplies dependency artifacts, synthesize and " \
                                  "persist a verified one-lane `stage-dependency-plan` v1 file with a known plan " \
                                  "id and `edges: []`, plus a `stage-dependency-gate` v1 live replay: use the " \
                                  "actual target/lane id, current full head/base SHAs, and already bound " \
                                  "maker/checker identities. Do not infer or placeholder-fill any fact. Missing " \
                                  "or `UNKNOWN` facts remain fail-closed and stop before mutation."
TRIAGE_MANIFEST_HANDOFF_CONTRACT = "Every separately handed-off prompt must name " \
                                   "`STAGE_DEPENDENCY_PLAN_PATH` and `STAGE_DEPENDENCY_PLAN_ID` in existing " \
                                   "`Scope` data and carry the complete live replay inline or name its durable " \
                                   "reference; persist or deliver both artifacts with stable planning state. " \
                                   "Backend storage is optional and must not be assumed."
BACKEND_TYPED_GATE_CONTRACT = "Known backend `depends_on`/`blocked_on` facts refresh the corresponding typed " \
                              "live edge state and evidence; they do not decide lifecycle capabilities. " \
                              "Run `stage-dependency-gate` and obey its returned permissions for the requested " \
                              "action. Set a blocked heartbeat or move away only when that permission is false. " \
                              "Missing or `UNKNOWN` backend dependency state remains a blanket hard stop."
COMPACT_BACKEND_TYPED_GATE_CONTRACT = "- For coordination, respect coordination claims and dependencies: " \
                                      "stable ids+heartbeats; register before launch when supported; claim " \
                                      "refusal=>stop; push holder/generation check; known deps=>gate permissions; " \
                                      "missing/UNKNOWN deps=>stop."
REQUIRED_DEPENDENCY_CLOSEOUT_CONTRACT = "A lane may perform helper-permitted intermediate work while dependencies " \
                                        "are pending, but it cannot be reported ready or closed out until every " \
                                        "required dependency edge is terminally satisfied."
LEGACY_COMPACT_BACKEND_STOP = "unmet blocked_on/dependency UNKNOWN -> stop."
TRUSTED_PLAN_CALL = '--trusted-plan "${STAGE_DEPENDENCY_PLAN_PATH}"'
TRUSTED_PLAN_ID_CALL = '--trusted-plan-id "${STAGE_DEPENDENCY_PLAN_ID}"'

class StageDependencyGateTest < Minitest::Test
  def test_instruction_surfaces_resolve_and_invoke_the_portable_helper
    surfaces = %w[
      skills/pr-batch/SKILL.md
      skills/plan-pr-batch/SKILL.md
      skills/triage/SKILL.md
      workflows/pr-processing.md
    ]

    surfaces.each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8")
      normalized_text = text.gsub(/\s+/, " ").strip
      HELPER_RESOLUTION_RULES.each do |rule|
        assert_includes normalized_text, rule, "#{path} is missing helper resolution rule: #{rule}"
      end
      assert_includes text, PORTABLE_HELPER_CALL, "#{path} must use the resolved portable helper"
      refute_includes text, REPOSITORY_RELATIVE_HELPER, "#{path} must not use a repository-relative helper"
    end
  end

  def test_direct_single_target_entry_synthesizes_a_verified_manifest_without_a_handoff
    %w[skills/pr-batch/SKILL.md workflows/pr-processing.md].each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_includes text, SINGLE_TARGET_MANIFEST_CONTRACT, "#{path} is missing direct single-target synthesis"
    end
  end

  def test_triage_handoffs_deliver_the_complete_manifest_or_a_durable_reference
    %w[skills/triage/SKILL.md workflows/pr-processing.md].each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_includes text, TRIAGE_MANIFEST_HANDOFF_CONTRACT, "#{path} is missing the triage manifest handoff"
    end
  end

  def test_backend_dependency_facts_defer_lifecycle_permissions_to_the_typed_gate
    permissions_for = lambda do |type|
      result = evaluate_with_matching_plan(
        "contract" => "stage-dependency-gate",
        "version" => 1,
        "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
        "edges" => [{
          "id" => "foundation-before-consumer-#{type}",
          "from" => "foundation",
          "to" => "consumer",
          "type" => type,
          "state" => "pending"
        }]
      )
      result.fetch("lanes").find { |lane_entry| lane_entry.fetch("id") == "consumer" }.fetch("permissions")
    end

    edit_permissions = permissions_for.call("edit")
    assert edit_permissions.fetch("read_only_discovery")
    refute edit_permissions.fetch("branch_worktree_create")

    validation_permissions = permissions_for.call("validation_open")
    assert validation_permissions.fetch("branch_worktree_create")
    assert validation_permissions.fetch("patch_edit")
    assert validation_permissions.fetch("commit")
    refute validation_permissions.fetch("push")

    merge_permissions = permissions_for.call("merge_order")
    assert merge_permissions.fetch("branch_worktree_create")
    assert merge_permissions.fetch("push")
    refute merge_permissions.fetch("merge")

    workflow = File.read(File.join(ROOT, "workflows/pr-processing.md"), encoding: "UTF-8").gsub(/\s+/, " ").strip
    assert_includes workflow, BACKEND_TYPED_GATE_CONTRACT
    %w[workflows/pr-processing.md skills/pr-batch/SKILL.md].each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_includes text, REQUIRED_DEPENDENCY_CLOSEOUT_CONTRACT,
                      "#{path} must keep readiness/closeout behind terminal dependency satisfaction"
    end

    compact_surfaces = %w[
      workflows/pr-processing.md
      skills/pr-batch/SKILL.md
      skills/plan-pr-batch/SKILL.md
    ]
    compact_surfaces.each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8")
      assert_includes text, COMPACT_BACKEND_TYPED_GATE_CONTRACT, "#{path} must defer known facts to the typed gate"
      refute_includes text, LEGACY_COMPACT_BACKEND_STOP, "#{path} must not blanket-stop known pending edges"
    end

    refute_includes workflow,
                    "set that lane's heartbeat status to `blocked`, report the blocked refs in the handoff, and move"
    refute_includes workflow,
                    "refresh its own heartbeat with `--status blocked`, switch to another independent lane"
    refute_includes workflow,
                    "sets heartbeat `--status blocked`, and moves to another independent lane"
  end

  def test_manifest_surfaces_pin_trusted_edge_plans_actor_fail_closed_and_preparation_replay
    manifest_surfaces = %w[
      workflows/pr-processing.md
      skills/pr-batch/SKILL.md
      skills/plan-pr-batch/SKILL.md
      skills/triage/SKILL.md
      docs/coordination-backend.md
    ]
    preparation_fields = %w[
      source_patch_inspection
      collision_domain_mapping
      semantic_adaptation_notes
      validation_review_plan
      evidence_templates
    ]

    manifest_surfaces.each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_match(/immutable pre-launch trusted plan.*`id`.*`from`.*`to`.*`type`/i, text,
                   "#{path} must pin the immutable edge tuple in a separate trusted plan")
      preparation_fields.each do |field|
        assert_includes text, "`#{field}`", "#{path} is missing preparation field #{field}"
      end
    end

    %w[workflows/pr-processing.md skills/pr-batch/SKILL.md].each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_includes text,
                      "Missing, empty, or `UNKNOWN` maker/checker identity permits read-only discovery only " \
                      "and blocks hosted CI and every mutation.",
                      "#{path} must fail closed before actor-bound mutation"
      assert_includes text,
                      "Legitimate reclassification requires a new edge id and a trusted coordinator re-plan.",
                      "#{path} must not allow in-place edge retyping"
    end

    context = File.read(File.join(ROOT, "CONTEXT.md"), encoding: "UTF-8").gsub(/\s+/, " ").strip
    assert_includes context, "immutable pre-launch trusted plan"
    assert_includes context, "Preparation replay"
  end

  def test_instruction_surfaces_separate_trusted_plan_from_live_replay_facts
    surfaces = %w[
      workflows/pr-processing.md
      skills/pr-batch/SKILL.md
      skills/plan-pr-batch/SKILL.md
      skills/triage/SKILL.md
      docs/coordination-backend.md
    ]

    surfaces.each do |path|
      text = File.read(File.join(ROOT, path), encoding: "UTF-8").gsub(/\s+/, " ").strip
      assert_includes text, "`stage-dependency-plan`", "#{path} must name the separate trusted plan contract"
      assert_includes text, TRUSTED_PLAN_CALL, "#{path} must pass the persisted plan separately"
      assert_includes text, TRUSTED_PLAN_ID_CALL, "#{path} must pin the coordinator-approved plan identity"
      assert_includes text, "live edges carry only `id`, `state`, `evidence`, and `base_movement`",
                      "#{path} must keep mutable tuple copies out of the live contract"
    end

    canonical = File.read(File.join(ROOT, "workflows/pr-processing.md"), encoding: "UTF-8").gsub(/\s+/, " ").strip
    assert_includes canonical,
                    "Backend `n/a` uses the same durable coordinator-owned local plan file; storage is a seam, " \
                    "not helper state."
    refute_includes canonical, "Every edge carries an immutable pre-launch edge `binding`"
  end

  def evaluate(input, trusted_plan:)
    evaluate_raw_with_trusted_plan(JSON.generate(input), trusted_plan)
  end

  def evaluate_with_matching_plan(input)
    plan_edges = input.fetch("edges", []).filter_map do |edge|
      edge.slice("id", "from", "to", "type") if edge.is_a?(Hash)
    end
    evaluate(
      input,
      trusted_plan: {
        "contract" => "stage-dependency-plan",
        "version" => 1,
        "id" => "explicit-test-plan",
        "edges" => plan_edges
      }
    )
  end

  def evaluate_raw(stdin_data)
    stdout, stderr, status = Open3.capture3(HELPER, stdin_data: stdin_data)
    assert status.success?, stderr

    JSON.parse(stdout)
  end

  def evaluate_raw_with_trusted_plan(stdin_data, trusted_plan)
    Tempfile.create(["stage-dependency-plan", ".json"]) do |plan_file|
      plan_file.write(JSON.generate(trusted_plan))
      plan_file.flush
      stdout, stderr, status = Open3.capture3(
        HELPER,
        "--trusted-plan",
        plan_file.path,
        "--trusted-plan-id",
        trusted_plan["id"].to_s,
        stdin_data: stdin_data
      )
      assert status.success?, stderr
      return JSON.parse(stdout)
    end
  end

  def lane(id, head_sha:, maker: "maker-#{id}", checker: "checker-#{id}", base_sha: BASE_SHA)
    {
      "id" => id,
      "maker" => maker,
      "checker" => checker,
      "head_sha" => head_sha,
      "base_sha" => base_sha,
      "preparation" => preparation
    }
  end

  def preparation
    {
      "source_patch_inspection" => "coordination://preparation/source-patch",
      "collision_domain_mapping" => "coordination://preparation/collision-domains",
      "semantic_adaptation_notes" => "coordination://preparation/semantic-adaptation",
      "validation_review_plan" => "coordination://preparation/validation-review",
      "evidence_templates" => "coordination://preparation/evidence-templates"
    }
  end

  def blocker_reasons(lane_result)
    lane_result.fetch("blockers").map { |blocker| blocker.fetch("reason") }
  end

  def test_trusted_plan_prevents_mutating_both_live_tuple_copies_to_unlock_work
    consumer_lane = lane("consumer", head_sha: SHA_B)
    consumer_lane["preparation"] = preparation
    trusted_plan = {
      "contract" => "stage-dependency-plan",
      "version" => 1,
      "id" => "trusted-plan-original",
      "edges" => [{
        "id" => "foundation-before-consumer",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "edit"
      }]
    }
    live_input = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), consumer_lane],
      "edges" => [{
        "id" => "foundation-before-consumer",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "merge_order",
        "binding" => {
          "id" => "foundation-before-consumer",
          "from" => "foundation",
          "to" => "consumer",
          "type" => "merge_order"
        },
        "state" => "pending"
      }]
    }
    result = evaluate_raw_with_trusted_plan(JSON.generate(live_input), trusted_plan)

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal ["pending"], blocker_reasons(consumer)
  end

  def test_missing_trusted_plan_stops_before_mutation
    result = evaluate_raw(JSON.generate(
                            "contract" => "stage-dependency-gate",
                            "version" => 1,
                            "lanes" => [lane("consumer", head_sha: SHA_B)],
                            "edges" => []
                          ))

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "trusted-plan-required", result.fetch("reason")
  end

  def test_retyping_a_bound_edge_id_fails_closed_before_stage_permissions
    consumer_lane = lane("consumer", head_sha: SHA_B)
    consumer_lane["preparation"] = nil
    live_input = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), consumer_lane],
      "edges" => [{
        "id" => "foundation-before-consumer",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "merge_order",
        "state" => "pending",
        "binding" => {
          "id" => "foundation-before-consumer",
          "from" => "foundation",
          "to" => "consumer",
          "type" => "validation_open"
        }
      }]
    }
    result = evaluate(
      live_input,
      trusted_plan: {
        "contract" => "stage-dependency-plan",
        "version" => 1,
        "id" => "trusted-validation-plan",
        "edges" => [{
          "id" => "foundation-before-consumer",
          "from" => "foundation",
          "to" => "consumer",
          "type" => "validation_open"
        }]
      }
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal %w[pending preparation-missing], blocker_reasons(consumer)
  end

  def test_unreadable_trusted_plan_stops_before_mutation
    input = JSON.generate(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("consumer", head_sha: SHA_B)],
      "edges" => []
    )
    stdout, stderr, status = Open3.capture3(
      HELPER,
      "--trusted-plan",
      "/definitely/missing/stage-dependency-plan.json",
      "--trusted-plan-id",
      "expected-unreadable-plan",
      stdin_data: input
    )
    assert status.success?, stderr
    result = JSON.parse(stdout)

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "trusted-plan-unreadable", result.fetch("reason")
  end

  def test_unknown_trusted_plan_identity_stops_before_mutation
    result = evaluate(
      {
        "contract" => "stage-dependency-gate",
        "version" => 1,
        "lanes" => [lane("consumer", head_sha: SHA_B)],
        "edges" => []
      },
      trusted_plan: {
        "contract" => "stage-dependency-plan",
        "version" => 1,
        "id" => " UNKNOWN ",
        "edges" => []
      }
    )

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "trusted-plan-id-invalid", result.fetch("reason")
  end

  def test_live_edge_absent_from_trusted_plan_stops_before_mutation
    result = evaluate(
      {
        "contract" => "stage-dependency-gate",
        "version" => 1,
        "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
        "edges" => [{ "id" => "unplanned-edge", "state" => "pending" }]
      },
      trusted_plan: {
        "contract" => "stage-dependency-plan",
        "version" => 1,
        "id" => "trusted-plan-without-live-edge",
        "edges" => []
      }
    )

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "live-edge-not-in-trusted-plan", result.fetch("reason")
  end

  def test_coordinator_pinned_plan_identity_mismatch_stops_before_mutation
    trusted_plan = {
      "contract" => "stage-dependency-plan",
      "version" => 1,
      "id" => "persisted-plan-a",
      "edges" => []
    }
    Tempfile.create(["stage-dependency-plan", ".json"]) do |plan_file|
      plan_file.write(JSON.generate(trusted_plan))
      plan_file.flush
      stdout, stderr, status = Open3.capture3(
        HELPER,
        "--trusted-plan",
        plan_file.path,
        "--trusted-plan-id",
        "coordinator-expected-plan-b",
        stdin_data: JSON.generate(
          "contract" => "stage-dependency-gate",
          "version" => 1,
          "lanes" => [lane("consumer", head_sha: SHA_B)],
          "edges" => []
        )
      )
      assert status.success?, stderr
      result = JSON.parse(stdout)
      assert_equal "invalid-input", result.fetch("status")
      assert_equal "trusted-plan-id-mismatch", result.fetch("reason")
    end
  end

  def test_pending_edit_edge_blocks_all_mutation_but_allows_read_only_discovery
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-edit",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "edit",
        "state" => "pending"
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    permissions = consumer.fetch("permissions")
    assert_equal true, permissions.fetch("read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, permissions.fetch(capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
  end

  def test_pending_validation_open_edge_allows_held_local_work_only
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "pending"
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    permissions = consumer.fetch("permissions")
    %w[read_only_discovery branch_worktree_create patch_edit commit].each do |capability|
      assert_equal true, permissions.fetch(capability), capability
    end
    %w[push pr_open final_validation merge].each do |capability|
      assert_equal false, permissions.fetch(capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
  end

  def test_pending_validation_open_requires_preparation_before_local_mutation
    consumer_lane = lane("consumer", head_sha: SHA_B)
    consumer_lane["preparation"] = nil
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), consumer_lane],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "pending"
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal %w[pending preparation-missing], blocker_reasons(consumer)
  end

  def test_unknown_preparation_field_fails_closed
    consumer_lane = lane("consumer", head_sha: SHA_B)
    consumer_lane["preparation"] = preparation.merge("semantic_adaptation_notes" => " UNKNOWN ")
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), consumer_lane],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "pending"
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal %w[pending preparation-unknown], blocker_reasons(consumer)
  end

  def test_satisfied_validation_open_edge_requires_current_head_and_base_evidence
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => SHA_B,
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "unchanged",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert consumer.fetch("permissions").values.all?
    assert_equal "eligible-via-repo-seam", consumer.fetch("hosted_ci")
    assert_empty consumer.fetch("blockers")
    assert_equal "required-via-repo-seam", result.dig("downstream_requirements", "final_combined_tip_validation")
    assert_equal %w[exact_head_ci independent_review unresolved_threads merge_readiness],
                 result.dig("downstream_requirements", "preserved_gates")
  end

  def test_satisfied_validation_open_edge_requires_explicit_refresh_facts
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => SHA_B,
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "unchanged",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal false, consumer.dig("permissions", "push")
    assert_equal false, consumer.dig("permissions", "final_validation")
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal ["base-refresh-input-unknown"], blocker_reasons(consumer)
  end

  def test_stale_validation_open_head_evidence_fails_closed
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => SHA_A,
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "unchanged",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    %w[push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal ["evidence-head-stale"], blocker_reasons(consumer)
  end

  def test_base_movement_with_semantic_overlap_requires_current_head_replay
    moved_base = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A),
                  lane("consumer", head_sha: SHA_B, base_sha: moved_base)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => SHA_B,
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "moved",
          "semantic_overlap" => true,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal false, consumer.dig("permissions", "push")
    assert_equal false, consumer.dig("permissions", "final_validation")
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal ["base-refresh-required"], blocker_reasons(consumer)
  end

  def test_independent_behind_base_branch_does_not_require_refresh
    moved_base = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A),
                  lane("consumer", head_sha: SHA_B, base_sha: moved_base)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => SHA_B,
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "moved",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert consumer.fetch("permissions").values.all?
    assert_equal "eligible-via-repo-seam", consumer.fetch("hosted_ci")
    assert_equal [{
      "edge_id" => "foundation-before-consumer-open",
      "required" => false,
      "reason" => "independent-behind-base"
    }], consumer.fetch("base_refresh")
  end

  def test_pending_merge_order_edge_blocks_only_merge
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("predecessor", head_sha: SHA_A), lane("successor", head_sha: SHA_B)],
      "edges" => [{
        "id" => "predecessor-before-successor-merge",
        "from" => "predecessor",
        "to" => "successor",
        "type" => "merge_order",
        "state" => "pending"
      }]
    )

    successor = result.fetch("lanes").find { |entry| entry.fetch("id") == "successor" }
    assert_equal true, successor.dig("permissions", "branch_worktree_create")
    assert_equal true, successor.dig("permissions", "patch_edit")
    assert_equal true, successor.dig("permissions", "commit")
    assert_equal true, successor.dig("permissions", "push")
    assert_equal true, successor.dig("permissions", "pr_open")
    assert_equal true, successor.dig("permissions", "final_validation")
    assert_equal false, successor.dig("permissions", "merge")
    assert_equal "eligible-via-repo-seam", successor.fetch("hosted_ci")
  end

  def test_merge_order_requires_merged_predecessor_terminal_evidence
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("predecessor", head_sha: SHA_A), lane("successor", head_sha: SHA_B)],
      "edges" => [{
        "id" => "predecessor-before-successor-merge",
        "from" => "predecessor",
        "to" => "successor",
        "type" => "merge_order",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "github://pull/100",
          "head_sha" => SHA_A,
          "terminal_state" => "closed"
        }
      }]
    )

    successor = result.fetch("lanes").find { |entry| entry.fetch("id") == "successor" }
    assert_equal false, successor.dig("permissions", "merge")
    assert_equal ["predecessor-not-merged"], blocker_reasons(successor)
  end

  def test_unknown_edge_type_fails_closed_at_the_earliest_mutation_stage
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "unclassified-dependency",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "UNKNOWN",
        "state" => "pending"
      }]
    )

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "trusted-plan-edge-tuple-invalid", result.fetch("reason")
  end

  def test_unknown_edge_state_fails_closed_at_the_earliest_mutation_stage
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "unknown-state-dependency",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "merge_order",
        "state" => "UNKNOWN"
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal ["edge-state-unknown"], blocker_reasons(consumer)
  end

  def test_maker_cannot_issue_the_checker_verdict
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("consumer", head_sha: SHA_B, maker: "same-actor", checker: "same-actor")],
      "edges" => []
    )

    consumer = result.fetch("lanes").first
    assert_equal false, consumer.dig("permissions", "merge")
    assert_equal ["maker-checker-not-distinct"], blocker_reasons(consumer)
    assert_equal "blocked", result.dig("checker_verdict", "status")
  end

  def test_every_checker_must_be_independent_from_every_batch_maker
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [
        lane("alpha", head_sha: SHA_A, maker: " Alice ", checker: "bOb"),
        lane("beta", head_sha: SHA_B, maker: " BOB ", checker: " alice ")
      ],
      "edges" => []
    )

    result.fetch("lanes").each do |lane_result|
      assert_equal false, lane_result.dig("permissions", "merge"), lane_result.fetch("id")
      assert_equal ["maker-checker-not-independent"], blocker_reasons(lane_result), lane_result.fetch("id")
    end
    assert_equal "blocked", result.dig("checker_verdict", "status")
    blocker_lane_ids = result.dig("checker_verdict", "blockers").map { |blocker| blocker.fetch("lane_id") }
    assert_equal %w[alpha beta], blocker_lane_ids
  end

  def test_shared_makers_and_shared_independent_checkers_remain_allowed
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [
        lane("alpha", head_sha: SHA_A, maker: " Alice ", checker: "independent-checker"),
        lane("beta", head_sha: SHA_B, maker: "ALICE", checker: " INDEPENDENT-CHECKER ")
      ],
      "edges" => []
    )

    assert_equal "eligible", result.fetch("status")
    assert_equal "eligible", result.dig("checker_verdict", "status")
    result.fetch("lanes").each do |lane_result|
      assert_equal true, lane_result.dig("permissions", "merge"), lane_result.fetch("id")
      assert_empty lane_result.fetch("blockers"), lane_result.fetch("id")
    end
  end

  def test_unknown_maker_or_checker_identity_blocks_the_checker_verdict
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("consumer", head_sha: SHA_B, maker: "UNKNOWN", checker: "checker-consumer")],
      "edges" => []
    )

    consumer = result.fetch("lanes").first
    assert_equal true, consumer.dig("permissions", "read_only_discovery")
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal "not-yet-eligible", consumer.fetch("hosted_ci")
    assert_equal ["maker-checker-identity-unknown"], blocker_reasons(consumer)
    assert_equal "blocked", result.dig("checker_verdict", "status")
  end

  def test_missing_or_empty_maker_checker_identity_allows_read_only_discovery_only
    missing_maker = lane("missing-maker", head_sha: SHA_A)
    missing_maker.delete("maker")
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [missing_maker, lane("empty-checker", head_sha: SHA_B, checker: "  ")],
      "edges" => []
    )

    result.fetch("lanes").each do |lane_result|
      assert_equal true, lane_result.dig("permissions", "read_only_discovery"), lane_result.fetch("id")
      %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
        assert_equal false, lane_result.dig("permissions", capability), "#{lane_result.fetch('id')}: #{capability}"
      end
      assert_equal "not-yet-eligible", lane_result.fetch("hosted_ci"), lane_result.fetch("id")
      assert_equal ["maker-checker-identity-unknown"], blocker_reasons(lane_result), lane_result.fetch("id")
    end
    assert_equal "blocked", result.dig("checker_verdict", "status")
  end

  def test_critical_path_uses_stable_lexicographic_tie_breaker
    lanes = [
      lane("foundation", head_sha: SHA_A),
      lane("api", head_sha: "3333333333333333333333333333333333333333"),
      lane("docs", head_sha: "4444444444444444444444444444444444444444"),
      lane("release", head_sha: SHA_B)
    ]
    edges = [
      { "id" => "foundation-api", "from" => "foundation", "to" => "api",
        "type" => "edit", "state" => "satisfied",
        "evidence" => { "evidence_ref" => "coordination://foundation/api" } },
      { "id" => "foundation-docs", "from" => "foundation", "to" => "docs",
        "type" => "edit", "state" => "satisfied",
        "evidence" => { "evidence_ref" => "coordination://foundation/docs" } },
      { "id" => "api-release", "from" => "api", "to" => "release",
        "type" => "merge_order", "state" => "pending" },
      { "id" => "docs-release", "from" => "docs", "to" => "release",
        "type" => "merge_order", "state" => "pending" }
    ]
    input = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => lanes,
      "edges" => edges
    }

    first = evaluate_with_matching_plan(input)
    replay = evaluate_with_matching_plan(input.merge("lanes" => lanes.reverse, "edges" => edges.reverse))
    expected = {
      "lane_ids" => %w[foundation api release],
      "edge_count" => 2,
      "tie_breaker" => "maximum-dependency-hops-then-lexicographic-lane-id-sequence",
      "assignments" => [
        { "lane_id" => "foundation", "maker" => "maker-foundation", "checker" => "checker-foundation" },
        { "lane_id" => "api", "maker" => "maker-api", "checker" => "checker-api" },
        { "lane_id" => "release", "maker" => "maker-release", "checker" => "checker-release" }
      ]
    }

    assert_equal expected, first.fetch("critical_path")
    assert_equal first.fetch("critical_path"), replay.fetch("critical_path")
    assert_equal first.fetch("lanes"), replay.fetch("lanes")
  end

  def test_satisfied_edge_requires_a_nonempty_evidence_ref
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-edit",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "edit",
        "state" => "satisfied",
        "evidence" => { "evidence_ref" => "  " }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
      assert_equal false, consumer.dig("permissions", capability), capability
    end
    assert_equal ["evidence-ref-missing"], blocker_reasons(consumer)
  end

  def test_head_sensitive_evidence_requires_a_full_sha
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "foundation-before-consumer-open",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://batch/lane/foundation/validation",
          "head_sha" => "2222222",
          "base_sha" => BASE_SHA
        },
        "base_movement" => {
          "status" => "unchanged",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |entry| entry.fetch("id") == "consumer" }
    assert_equal false, consumer.dig("permissions", "final_validation")
    assert_equal ["evidence-head-malformed"], blocker_reasons(consumer)
  end

  def test_hostile_and_motivating_replay_fixtures
    fixture = JSON.parse(File.read(REPLAY_FIXTURES, encoding: "UTF-8"))
    assert_equal "stage-dependency-gate-replays", fixture.fetch("contract")
    assert_equal 1, fixture.fetch("version")

    fixture.fetch("cases").each do |test_case|
      input = if test_case.key?("template")
                template = fixture.fetch("templates").fetch(test_case.fetch("template"))
                JSON.parse(JSON.generate(template)).merge("edges" => test_case.fetch("edges"))
              else
                test_case.fetch("input")
              end
      test_case.fetch("lane_overrides", {}).each do |lane_id, overrides|
        input.fetch("lanes").find { |lane_record| lane_record.fetch("id") == lane_id }.merge!(overrides)
      end
      trusted_plan = test_case.fetch("trusted_plan")
      result = evaluate_raw_with_trusted_plan(JSON.generate(input), trusted_plan)
      replay = evaluate_raw_with_trusted_plan(JSON.generate(input), trusted_plan)
      assert_equal result, replay, test_case.fetch("name")

      expected = test_case.fetch("expected")
      assert_equal expected.fetch("status"), result.fetch("status"), test_case.fetch("name")
      if expected.fetch("status") == "invalid-input"
        assert_equal expected.fetch("reason"), result.fetch("reason"), test_case.fetch("name")
        next
      end
      expected.fetch("lane_results", [expected]).each do |lane_expectation|
        lane_result = result.fetch("lanes").find do |lane_entry|
          lane_entry.fetch("id") == lane_expectation.fetch("lane_id")
        end
        assert_equal lane_expectation.fetch("hosted_ci"), lane_result.fetch("hosted_ci"), test_case.fetch("name")
        lane_expectation.fetch("blocked_capabilities").each do |capability|
          assert_equal false, lane_result.dig("permissions", capability), "#{test_case.fetch('name')}: #{capability}"
        end
        lane_expectation.fetch("allowed_capabilities", []).each do |capability|
          assert_equal true, lane_result.dig("permissions", capability), "#{test_case.fetch('name')}: #{capability}"
        end
        assert_equal lane_expectation.fetch("blocker_reasons"),
                     lane_result.fetch("blockers").map { |blocker| blocker.fetch("reason") },
                     test_case.fetch("name")
        if lane_expectation.key?("base_refresh")
          assert_equal lane_expectation.fetch("base_refresh"), lane_result.fetch("base_refresh"), test_case.fetch("name")
        end
      end
      assert_equal expected.fetch("checker_status"), result.dig("checker_verdict", "status"), test_case.fetch("name") if expected.key?("checker_status")
      assert_equal expected.fetch("critical_path"), result.fetch("critical_path"), test_case.fetch("name") if expected.key?("critical_path")
      if expected.key?("downstream_requirements")
        assert_equal expected.fetch("downstream_requirements"), result.fetch("downstream_requirements"), test_case.fetch("name")
      end
    end
  end

  def test_durable_replays_carry_separate_trusted_plans_without_hidden_completion
    fixture = JSON.parse(File.read(REPLAY_FIXTURES, encoding: "UTF-8"))

    fixture.fetch("cases").each do |test_case|
      plan = test_case["trusted_plan"]
      assert_kind_of Hash, plan, "#{test_case.fetch('name')}: trusted plan missing"
      assert_equal "stage-dependency-plan", plan["contract"], test_case.fetch("name")
      assert_equal 1, plan["version"], test_case.fetch("name")
      refute_nil plan["id"], test_case.fetch("name")
      assert_kind_of Array, plan["edges"], test_case.fetch("name")

      input = if test_case.key?("template")
                template = fixture.fetch("templates").fetch(test_case.fetch("template"))
                JSON.parse(JSON.generate(template)).merge("edges" => test_case.fetch("edges"))
              else
                JSON.parse(JSON.generate(test_case.fetch("input")))
              end
      test_case.fetch("lane_overrides", {}).each do |lane_id, overrides|
        input.fetch("lanes").find { |lane_record| lane_record.fetch("id") == lane_id }.merge!(overrides)
      end
      live_ids = input.fetch("edges").map { |edge| edge.fetch("id") }
      plan_ids = plan.fetch("edges").map { |edge| edge.fetch("id") }
      assert_equal plan_ids.sort, live_ids.sort, "#{test_case.fetch('name')}: live/plan edge ids differ"

      unless test_case.fetch("name") == "same-edge-id-retyped-after-launch"
        input.fetch("edges").each do |live_edge|
          %w[from to type binding].each do |immutable_key|
            refute live_edge.key?(immutable_key),
                   "#{test_case.fetch('name')}: live edge contains immutable #{immutable_key}"
          end
        end
      end

      plan.fetch("edges").each do |planned_edge|
        unless test_case.fetch("name") == "missing-edge-type"
          %w[id from to type].each do |immutable_key|
            assert planned_edge.key?(immutable_key),
                   "#{test_case.fetch('name')}: trusted plan omits #{immutable_key}"
          end
        end
        live_edge = input.fetch("edges").find { |edge| edge.fetch("id") == planned_edge.fetch("id") }
        next unless live_edge["state"] == "pending"
        next unless %w[edit validation_open].include?(planned_edge["type"])
        next if test_case.fetch("name").match?(/missing-preparation|unknown-preparation/)

        lane_record = input.fetch("lanes").find { |lane| lane.fetch("id") == planned_edge.fetch("to") }
        assert_equal preparation, lane_record["preparation"],
                     "#{test_case.fetch('name')}: pending lane preparation incomplete"
      end
    end
  end

  def test_unsupported_contract_version_returns_deterministic_json_error
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 2,
      "lanes" => [],
      "edges" => []
    )

    expected = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "status" => "invalid-input",
      "reason" => "unsupported-contract-version"
    }
    assert_equal expected, result
  end

  def test_empty_lane_array_is_invalid_input
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [],
      "edges" => []
    )

    expected = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "status" => "invalid-input",
      "reason" => "lane-array-empty"
    }
    assert_equal expected, result

    workflow = File.read(File.join(ROOT, "workflows/pr-processing.md"), encoding: "UTF-8").gsub(/\s+/, " ").strip
    assert_includes workflow, "Only `edges` may be empty; `lanes` must contain at least one verified lane."
  end

  def test_malformed_json_still_returns_json_output
    result = evaluate_raw("{not-json")

    expected = {
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "status" => "invalid-input",
      "reason" => "malformed-json"
    }
    assert_equal expected, result
  end

  def test_dependency_cycle_fails_closed_instead_of_inventing_a_critical_path
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("alpha", head_sha: SHA_A), lane("beta", head_sha: SHA_B)],
      "edges" => [
        { "id" => "alpha-beta", "from" => "alpha", "to" => "beta", "type" => "edit",
          "state" => "satisfied", "evidence" => { "evidence_ref" => "coordination://alpha/beta" } },
        { "id" => "beta-alpha", "from" => "beta", "to" => "alpha", "type" => "edit",
          "state" => "satisfied", "evidence" => { "evidence_ref" => "coordination://beta/alpha" } }
      ]
    )

    assert_equal "gated", result.fetch("status")
    result.fetch("lanes").each do |lane_result|
      assert_equal true, lane_result.dig("permissions", "read_only_discovery")
      %w[branch_worktree_create patch_edit commit push pr_open final_validation merge].each do |capability|
        assert_equal false, lane_result.dig("permissions", capability), "#{lane_result.fetch('id')}: #{capability}"
      end
      assert_includes lane_result.fetch("blockers").map { |blocker| blocker.fetch("reason") }, "dependency-cycle"
    end
    assert_equal "dependency-cycle", result.dig("critical_path", "reason")
    assert_empty result.dig("critical_path", "lane_ids")
  end

  def test_edge_endpoint_outside_the_declared_lane_set_is_invalid_input
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "missing-foundation",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "edit",
        "state" => "pending"
      }]
    )

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "trusted-plan-edge-endpoint-unknown", result.fetch("reason")
  end

  def test_lane_and_edge_ids_must_be_nonempty_and_unique
    duplicate_lane = lane("consumer", head_sha: SHA_B)
    lane_result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [duplicate_lane, duplicate_lane],
      "edges" => []
    )
    edge_result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [
        { "id" => "duplicate", "from" => "foundation", "to" => "consumer", "type" => "edit", "state" => "pending" },
        { "id" => "duplicate", "from" => "foundation", "to" => "consumer", "type" => "merge_order", "state" => "pending" }
      ]
    )

    assert_equal "lane-id-invalid-or-duplicate", lane_result.fetch("reason")
    assert_equal "edge-id-invalid-or-duplicate", edge_result.fetch("reason")
  end

  def test_lane_current_head_and_base_bindings_must_be_full_shas
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("consumer", head_sha: "2222222")],
      "edges" => []
    )

    assert_equal "invalid-input", result.fetch("status")
    assert_equal "lane-head-or-base-sha-malformed", result.fetch("reason")
  end

  def test_full_sha_bindings_compare_by_hex_value
    result = evaluate_with_matching_plan(
      "contract" => "stage-dependency-gate",
      "version" => 1,
      "lanes" => [lane("foundation", head_sha: SHA_A), lane("consumer", head_sha: SHA_B)],
      "edges" => [{
        "id" => "uppercase-binding",
        "from" => "foundation",
        "to" => "consumer",
        "type" => "validation_open",
        "state" => "satisfied",
        "evidence" => {
          "evidence_ref" => "coordination://foundation/validation",
          "head_sha" => SHA_B.upcase,
          "base_sha" => BASE_SHA.upcase
        },
        "base_movement" => {
          "status" => "unchanged",
          "semantic_overlap" => false,
          "required_dependency" => false,
          "conflict_or_base_sensitive" => false,
          "consumer_policy" => false
        }
      }]
    )

    consumer = result.fetch("lanes").find { |lane_result| lane_result.fetch("id") == "consumer" }
    assert_empty consumer.fetch("blockers")
    assert_equal "eligible", result.fetch("status")
  end
end
