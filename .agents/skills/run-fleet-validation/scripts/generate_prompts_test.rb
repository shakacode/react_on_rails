#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require_relative "generate_prompts"

class FleetValidationGeneratorTest < Minitest::Test
  MANIFEST = File.expand_path("../../../../internal/contributor-info/demo-fleet.yml", __dir__)
  VALIDATOR = File.expand_path("validate_ledger.rb", __dir__)
  RC12_REPLAY = File.expand_path("replay_rc12_lifecycle.rb", __dir__)

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

  def resolved_packages(generator)
    generator.lifecycle_inventory.flat_map { |target| target.fetch("packages") }
             .uniq { |package| [package["ecosystem"], package["name"]] }
             .map do |package|
      product_names = FleetValidation::LedgerValidator::PRODUCT_PACKAGES.fetch(package["ecosystem"], [])
      version = if product_names.include?(package["name"])
                  package["ecosystem"] == "gem" ? "17.0.0.rc.12" : "17.0.0-rc.12"
                else
                  "1.0.0"
                end
      package.merge("version" => version, "source" => "registry")
    end
  end

  def complete_ledger(generator)
    ledger = generator.ledger_template
    ledger.fetch("pack").merge!(
      "candidate" => "v17.0.0.rc.12",
      "candidate_commit" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "policy_commit" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "tracker_mode" => "strict-rc",
      "resolved_packages" => resolved_packages(generator)
    )
    ledger.fetch("preflight")["status"] = "passed"
    ledger.fetch("preflight")["app_work_allowed"] = true
    ledger.fetch("preflight")["opened_at"] = "2026-07-18T10:00:00Z"
    %w[release_ci artifacts generator_matrix].each do |gate|
      ledger.fetch("preflight").fetch(gate).merge!("status" => "passed", "evidence" => "public-safe evidence")
    end
    ledger.fetch("preflight").fetch("capabilities").transform_values! { "passed" }
    ledger.fetch("preflight").fetch("capabilities")["restart_handoff"] = "restart-safe handoff"
    ledger.fetch("inventory").each do |item|
      revision = if item["work_mode"] == "report_only"
                   "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
                 else
                   "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
                 end
      baseline_head = item["work_mode"] == "mutation" ? "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" : revision
      item.merge!(
        "maker_id" => item["work_mode"] == "mutation" ? "maker-1" : nil,
        "work_state" => "finished",
        "result" => item["tier"] == "hard_gate" ? "passed" : "reported",
        "work_started_at" => "2026-07-18T10:01:00Z",
        "evidence" => "public-safe evidence"
      )
      expected = generator.lifecycle_inventory.find { |target| target["id"] == item["id"] }
      item["package_locks"] = expected.fetch("packages").map do |package|
        resolved = ledger.fetch("pack").fetch("resolved_packages").find do |candidate_package|
          candidate_package.slice("ecosystem", "name") == package.slice("ecosystem", "name")
        end
        resolved.dup
      end
      item.fetch("checks").each_value do |check|
        check.merge!("status" => "passed", "head_commit" => revision, "evidence" => "public-safe evidence")
      end
      item.fetch("review_app").merge!(
        "state" => "not_configured",
        "head_commit" => revision,
        "evidence" => "not configured",
        "deployed_smoke" => "waived"
      )
      item.fetch("baseline").merge!(
        "classification" => "clean",
        "head_commit" => baseline_head,
        "evidence" => "fresh default passed"
      )
      item.fetch("revisions").merge!(
        "audit" => revision,
        "reviewed" => revision,
        "current" => revision,
        "reconciliation" => "passed"
      )
      item.fetch("bases").merge!(
        "audit" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "reviewed" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "current" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "reconciliation" => "passed"
      )
      if item["work_mode"] == "mutation"
        item.fetch("merge").merge!(
          "status" => "merged",
          "authority" => "auto_merge_when_gates_pass",
          "authority_evidence" => "trusted batch goal",
          "freeze_state" => "clear",
          "merge_commit" => "cccccccccccccccccccccccccccccccccccccccc",
          "evidence" => "public-safe merge evidence"
        )
      else
        item.fetch("merge").merge!(
          "status" => "not_applicable",
          "freeze_state" => "clear",
          "evidence" => "no mutable branch"
        )
      end
      item.fetch("reachability").merge!(
        "default_branch" => "passed",
        "default_commit" => "cccccccccccccccccccccccccccccccccccccccc",
        "default_evidence" => "public-safe evidence",
        "tree_parity" => "passed",
        "tree" => "dddddddddddddddddddddddddddddddddddddddd",
        "tree_evidence" => "public-safe evidence"
      )
    end
    ledger.fetch("required_paths").each do |path|
      path.merge!("status" => "passed", "lane" => "sanitized-lane", "evidence" => "public-safe evidence")
    end
    ledger.fetch("audit").merge!(
      "status" => "passed",
      "checker" => "independent-checker",
      "maker_ids" => ["maker-1"],
      "evidence" => "public-safe independent audit report"
    )
    ledger.fetch("merge")["status"] = "merged"
    ledger.fetch("reachability").merge!("default_branch" => "passed", "tree_parity" => "passed")
    ledger.fetch("tracker").merge!(
      "status" => "ready",
      "comment_url" => "https://example.invalid/tracker-comment",
      "promotion" => "recommend"
    )
    ledger
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

  def test_lifecycle_inventory_includes_every_hard_gate_and_report_only_soft_track
    inventory = build_generator.lifecycle_inventory

    assert_equal 8, (inventory.count { |target| target.fetch("tier") == "hard_gate" })
    assert_equal 5, (inventory.count { |target| target.fetch("tier") == "soft_track" })
    core = inventory.find { |target| target.fetch("id") == "react-on-rails-generator-install-smoke" }
    assert_equal "validation_only", core.fetch("work_mode")
    assert(inventory.select { |target| target.fetch("tier") == "soft_track" }
                    .all? { |target| target.fetch("work_mode") == "report_only" })
  end

  def test_ledger_inventory_cannot_downgrade_or_duplicate_a_manifest_hard_gate
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.merge!("tier" => "soft_track", "work_mode" => "report_only", "result" => "reported")
    ledger.fetch("inventory") << ledger.fetch("inventory").last.dup

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("classification does not match manifest") })
    assert(errors.any? { |error| error.include?("duplicate target") })
  end

  def test_report_only_prompt_covers_all_five_soft_tracks_without_mutation
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      report_only = File.read(File.join(directory, "REPORT-ONLY.md"))

      assert_equal 5, (report_only.lines.count { |line| line.include?("Report only; do not mutate") })
      assert_includes report_only, "fresh default"
      assert_includes report_only, "archived or deferred disposition"
    end
  end

  def test_writes_lifecycle_inventory_and_closeout_artifacts
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)

      %w[LIFECYCLE.md PREFLIGHT.md REPORT-ONLY.md CLOSEOUT.md result-ledger.json result-ledger.schema.json].each do |name|
        assert File.exist?(File.join(directory, name)), "expected generated #{name}"
      end
    end
  end

  def test_declares_required_web_pack_rsc_path_before_closeout
    required_path_ids = build_generator.required_paths.map { |path| path.fetch("id") }

    assert_includes required_path_ids, "webpack-rsc-production"
  end

  def test_generated_preflight_is_a_terminal_barrier_with_restart_safe_capability_evidence
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      preflight = File.read(File.join(directory, "PREFLIGHT.md"))
      maker_prompt = Dir.glob(File.join(directory, "*", "*-fleet-lane.md")).min.then { |path| File.read(path) }

      assert_includes preflight, "APP_WORK_ALLOWED"
      assert_includes preflight, "release commit CI"
      assert_includes preflight, "registry and tarball artifacts"
      assert_includes preflight, "standard / Pro / Pro+RSC generator matrix"
      assert_includes preflight, "nonblocking permissions"
      assert_includes preflight, "restart-safe handoff"
      assert_includes preflight,
                      "configured/runnable, configured/broken, not configured, or `UNKNOWN`"
      assert_includes maker_prompt, "`preflight.app_work_allowed: true` records the"
    end
  end

  def test_lifecycle_artifact_orders_snapshot_preflight_inventory_audit_merge_and_closeout
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      lifecycle = File.read(File.join(directory, "LIFECYCLE.md"))

      phases = [
        "Phase 0 — snapshot",
        "Phase 1 — capability preflight",
        "Phase 2 — release-wide barrier",
        "Phase 3 — fleet execution",
        "Phase 4 — independent audit",
        "Phase 5 — authorized merge",
        "Phase 6 — reachability and tree parity",
        "Phase 7 — tracker closeout"
      ]
      phases.each_cons(2) do |first, second|
        assert_operator lifecycle.index(first), :<, lifecycle.index(second)
      end
      assert_includes lifecycle, "webpack-rsc-production"
    end
  end

  def test_ledger_blocks_app_work_until_release_preflight_passes_or_is_waived
    generator = build_generator
    ledger = generator.ledger_template
    ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }["work_state"] = "running"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "app work started before APP_WORK_ALLOWED"
  end

  def test_app_work_allowed_is_an_explicit_schema_validated_ledger_marker
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("preflight")["app_work_allowed"] = false

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "app work started before APP_WORK_ALLOWED"
    assert_empty FleetValidation::SchemaValidator.new(generator.ledger_schema).errors(ledger)
  end

  def test_app_work_allowed_requires_the_exact_pack_snapshot_and_restart_handoff
    generator = build_generator
    missing_snapshot = complete_ledger(generator)
    missing_snapshot.fetch("pack")["candidate_commit"] = nil
    missing_handoff = complete_ledger(generator)
    missing_handoff.fetch("preflight").fetch("capabilities")["restart_handoff"] = nil

    [missing_snapshot, missing_handoff].each do |ledger|
      errors = FleetValidation::LedgerValidator.new(
        ledger,
        inventory: generator.lifecycle_inventory,
        required_paths: generator.required_paths,
        expected_candidate: "v17.0.0.rc.12",
        expected_snapshot_fingerprint: generator.snapshot_fingerprint
      ).errors

      assert_includes errors, "app work started before APP_WORK_ALLOWED"
    end
  end

  def test_closeout_preserves_barrier_before_work_start_ordering
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target["work_started_at"] = "2026-07-18T09:59:00Z"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("started before the preflight barrier opened") })
  end

  def test_ledger_fails_closed_when_a_report_only_soft_track_is_missing
    generator = build_generator
    ledger = generator.ledger_template
    removed = ledger.fetch("inventory").find { |item| item["tier"] == "soft_track" }
    ledger.fetch("inventory").delete(removed)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "inventory missing target #{removed.fetch('id')}"
  end

  def test_ledger_rejects_a_stale_candidate_pack
    generator = build_generator(release_selector: "v17.0.0.rc.12")
    ledger = generator.ledger_template
    ledger.fetch("pack")["candidate"] = "v17.0.0.rc.11"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12"
    ).errors

    assert_includes errors, "candidate mismatch: pinned selector v17.0.0.rc.12, got v17.0.0.rc.11"
  end

  def test_ledger_rejects_unknown_coordination_or_machine_capabilities
    generator = build_generator
    ledger = generator.ledger_template
    capabilities = ledger.fetch("preflight").fetch("capabilities")
    capabilities["coordination"] = "unknown"
    capabilities["permissions"] = "unknown"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "capability coordination is UNKNOWN"
    assert_includes errors, "capability permissions is UNKNOWN"
  end

  def test_review_app_capability_accepts_not_configured_but_rejects_unknown_after_work_starts
    generator = build_generator
    unknown_ledger = generator.ledger_template
    unknown_ledger.fetch("preflight")["status"] = "passed"
    target = unknown_ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target["work_state"] = "running"
    unknown_errors = FleetValidation::LedgerValidator.new(
      unknown_ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    target.fetch("review_app")["state"] = "not_configured"
    absent_errors = FleetValidation::LedgerValidator.new(
      unknown_ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes unknown_errors, "review app capability UNKNOWN for 1 started target(s)"
    refute_includes absent_errors, "review app capability UNKNOWN for 1 started target(s)"
  end

  def test_closeout_requires_terminal_evidence_for_configured_review_apps
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target.fetch("review_app").merge!(
      "state" => "configured_runnable",
      "deployed_smoke" => "pending",
      "evidence" => "configuration found"
    )

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("review-app smoke is not terminal") })
  end

  def test_closeout_fails_when_required_web_pack_rsc_path_has_no_evidence_or_waiver
    generator = build_generator
    ledger = generator.ledger_template

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "required path webpack-rsc-production has no passing, blocked, or waived evidence"
  end

  def test_owned_blocked_required_path_can_close_with_a_blocked_verdict
    generator = build_generator
    ledger = complete_ledger(generator)
    path = ledger.fetch("required_paths").find { |item| item["id"] == "webpack-rsc-production" }
    path.merge!(
      "status" => "blocked",
      "lane" => "sanitized-lane",
      "evidence" => "candidate path failed",
      "blocker_id" => "required-path-blocker"
    )
    ledger["blockers"] = [
      {
        "id" => "required-path-blocker",
        "status" => "open",
        "public_summary" => "Sanitized required path failure",
        "owner" => { "issue_url" => "https://example.invalid/issues/required-path" },
        "disposition" => nil
      }
    ]
    ledger.fetch("tracker")["promotion"] = "blocked"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_empty errors
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: BLOCKED"
  end

  def test_all_six_sanitized_closeout_blockers_require_durable_owners
    generator = build_generator
    ledger = generator.ledger_template
    ledger["blockers"] = (1..6).map do |number|
      {
        "id" => "blocker-#{number}",
        "status" => "open",
        "public_summary" => "Sanitized closeout blocker #{number}",
        "owner" => nil,
        "disposition" => nil
      }
    end

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors.grep(/has no durable owner/)

    assert_equal 6, errors.length
  end

  def test_waived_and_deferred_blockers_require_structured_disposition_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = %w[waived deferred].map do |status|
      {
        "id" => "#{status}-blocker",
        "status" => status,
        "public_summary" => "Sanitized #{status} blocker",
        "owner" => { "issue_url" => "https://example.invalid/issues/#{status}" },
        "disposition" => nil
      }
    end
    ledger.fetch("tracker")["promotion"] = "hold"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "blocker waived-blocker is missing structured waived disposition evidence"
    assert_includes errors, "blocker deferred-blocker is missing structured deferred disposition evidence"
  end

  def test_waived_and_deferred_blockers_require_durable_owners_in_addition_to_dispositions
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = %w[waived deferred].map do |status|
      {
        "id" => "#{status}-blocker",
        "status" => status,
        "public_summary" => "Sanitized #{status} blocker",
        "owner" => nil,
        "disposition" => {
          "gate" => "#{status}-blocker",
          "authority" => "maintainer",
          "evidence_url" => "https://example.invalid/dispositions/#{status}",
          "reason" => "Sanitized disposition"
        }
      }
    end
    ledger.fetch("tracker")["promotion"] = "hold"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "blocker waived-blocker has no durable owner"
    assert_includes errors, "blocker deferred-blocker has no durable owner"
  end

  def test_whitespace_only_blocker_ownership_and_disposition_evidence_is_rejected
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = [
      {
        "id" => "deferred-blocker",
        "status" => "deferred",
        "public_summary" => "Sanitized deferred blocker",
        "owner" => { "public_tracker_reason" => "   " },
        "disposition" => {
          "gate" => "deferred-blocker",
          "authority" => "   ",
          "evidence_url" => "   ",
          "reason" => "   "
        }
      }
    ]
    ledger.fetch("tracker")["promotion"] = "hold"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "blocker deferred-blocker is missing structured deferred disposition evidence"
    assert_includes errors, "blocker deferred-blocker has no durable owner"
  end

  def test_closeout_rejects_duplicate_blocker_ids
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = [
      {
        "id" => "duplicate-blocker",
        "status" => "resolved",
        "public_summary" => "First sanitized blocker",
        "owner" => nil,
        "disposition" => nil
      },
      {
        "id" => "duplicate-blocker",
        "status" => "resolved",
        "public_summary" => "Second sanitized blocker",
        "owner" => nil,
        "disposition" => nil
      }
    ]

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "blocker IDs must be unique: duplicate-blocker"
  end

  def test_public_ledger_rejects_private_blocker_fields
    generator = build_generator
    ledger = generator.ledger_template
    ledger["blockers"] = [
      {
        "id" => "blocker-1",
        "status" => "open",
        "public_summary" => "Sanitized blocker",
        "owner" => { "public_tracker_reason" => "Public identity cannot be exposed" },
        "disposition" => nil,
        "deployment_url" => "redacted"
      }
    ]

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "blocker blocker-1 contains forbidden private field deployment_url"
  end

  def test_closeout_requires_reconciliation_when_the_default_base_moves
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("bases").merge!("reviewed" => "target-before", "current" => "target-after", "reconciliation" => "blocked")

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "base moved after audit without passing reconciliation"
  end

  def test_closeout_requires_per_target_audit_reviewed_and_current_base_identities
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("bases").merge!("audit" => nil, "reviewed" => nil, "current" => nil)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("audit base is missing") })
    assert(errors.any? { |error| error.include?("reviewed base is missing") })
    assert(errors.any? { |error| error.include?("current base is missing") })
  end

  def test_generated_closeout_requires_independent_audit_authorized_merge_reachability_and_tree_parity
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      closeout = File.read(File.join(directory, "CLOSEOUT.md"))

      assert_includes closeout, "independent checker"
      assert_includes closeout, "tracker mode and freeze"
      assert_includes closeout, "explicit merge authority"
      assert_includes closeout, "default-branch reachability"
      assert_includes closeout, "tree parity"
      assert_includes closeout, "replayable public-safe evidence"
      assert_includes closeout, "every check head"
      assert_includes closeout, "merge commit"
      assert_includes closeout, "PASS`, `PARTIAL`, or `BLOCKED"
    end
  end

  def test_closeout_rejects_a_checker_that_was_also_a_maker
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("audit")["checker"] = "maker-1"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "independent audit checker is also a maker"
  end

  def test_independent_audit_maker_list_covers_every_mutable_target
    generator = build_generator
    ledger = complete_ledger(generator)
    mutable = ledger.fetch("inventory").select { |item| item["work_mode"] == "mutation" }
    mutable.each_with_index { |item, index| item["maker_id"] = "maker-#{index + 1}" }
    ledger.fetch("audit")["maker_ids"] = mutable.drop(1).map { |item| item.fetch("maker_id") }

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "independent audit maker identities do not cover every mutable target"
  end

  def test_independent_audit_rejects_blank_maker_identities
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory").select { |item| item["work_mode"] == "mutation" }.each do |item|
      item["maker_id"] = "   "
    end
    ledger.fetch("audit")["maker_ids"] = ["   "]

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "independent audit maker identities contain blank values"
  end

  def test_closeout_requires_identified_checker_and_makers
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("audit").merge!("checker" => nil, "maker_ids" => [])

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "independent audit checker is missing"
    assert_includes errors, "independent audit maker identities are missing"
  end

  def test_closeout_rejects_a_pending_independent_audit
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("audit")["status"] = "pending"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "independent audit is not passed"
  end

  def test_closeout_requires_replayable_independent_audit_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("audit")["evidence"] = "   "

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "independent audit evidence is missing"
  end

  def test_closeout_requires_a_restart_safe_capability_handoff
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("preflight").fetch("capabilities")["restart_handoff"] = nil

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "capability restart_handoff is missing"
  end

  def test_closeout_requires_all_release_wide_preflight_gates_to_pass
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("preflight").fetch("artifacts")["status"] = "unknown"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "release-wide preflight artifacts is not passed or explicitly waived"
  end

  def test_owned_preflight_blocker_can_close_without_opening_the_app_work_barrier
    generator = build_generator
    ledger = generator.ledger_template
    ledger.fetch("pack").merge!(
      "candidate" => "v17.0.0.rc.12",
      "candidate_commit" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "policy_commit" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "tracker_mode" => "strict-rc",
      "resolved_packages" => resolved_packages(generator)
    )
    ledger.fetch("preflight").merge!(
      "status" => "blocked",
      "app_work_allowed" => false,
      "blocker_id" => "artifact-blocker",
      "blocker_evidence" => "public-safe artifact mismatch evidence"
    )
    ledger.fetch("preflight").fetch("artifacts").merge!(
      "status" => "blocked",
      "evidence" => "public-safe artifact mismatch evidence"
    )
    ledger["blockers"] = [
      {
        "id" => "artifact-blocker",
        "status" => "open",
        "public_summary" => "Published candidate artifacts are incoherent",
        "owner" => { "issue_url" => "https://example.invalid/issues/artifact-blocker" },
        "disposition" => nil
      }
    ]
    ledger.fetch("audit").merge!(
      "status" => "passed",
      "checker" => "independent-checker",
      "maker_ids" => [],
      "evidence" => "public-safe blocked-preflight audit"
    )
    ledger.fetch("merge")["status"] = "blocked"
    ledger.fetch("reachability").merge!("default_branch" => "blocked", "tree_parity" => "blocked")
    ledger.fetch("tracker").merge!("status" => "ready", "promotion" => "blocked")

    schema_errors = FleetValidation::SchemaValidator.new(generator.ledger_schema).errors(ledger)
    semantic_errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      expected_snapshot_fingerprint: generator.snapshot_fingerprint,
      closeout: true
    ).errors

    assert_empty schema_errors
    assert_empty semantic_errors
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: BLOCKED"
  end

  def test_published_artifact_defects_cannot_be_waived
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("preflight").merge!(
      "status" => "waived",
      "waiver" => {
        "gate" => "artifacts",
        "authority" => "maintainer",
        "evidence_url" => "https://example.invalid/waiver",
        "reason" => "sanitized"
      }
    )
    ledger.fetch("preflight").fetch("artifacts")["status"] = "blocked"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "release-wide preflight artifacts must pass and cannot be waived"
  end

  def test_release_wide_preflight_passes_require_retained_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("preflight").fetch("release_ci")["evidence"] = nil

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "release-wide preflight release_ci is not passed or explicitly waived"
  end

  def test_empty_preflight_waiver_does_not_open_the_app_work_barrier
    generator = build_generator
    ledger = generator.ledger_template
    ledger.fetch("preflight").merge!("status" => "waived", "waiver" => {})
    ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }["work_state"] = "running"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths
    ).errors

    assert_includes errors, "app work started before APP_WORK_ALLOWED"
  end

  def test_closeout_rejects_unknown_or_nonterminal_inventory_results
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory").first["result"] = "unknown"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "1 inventory target(s) are unknown or nonterminal"
  end

  def test_closeout_requires_candidate_policy_and_default_snapshot_identities
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("pack")["policy_commit"] = nil

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "pack policy_commit is missing"
  end

  def test_closeout_rejects_unknown_snapshot_identities_and_tracker_modes
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("pack").merge!(
      "candidate_commit" => "unknown",
      "policy_commit" => "pending",
      "tracker_mode" => "unknown"
    )

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "pack candidate_commit is not an exact commit identity"
    assert_includes errors, "pack policy_commit is not an exact commit identity"
    assert_includes errors, "pack tracker_mode is not allowed"
  end

  def test_closeout_requires_full_length_commit_identities
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("pack")["candidate_commit"] = "abc1234"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "pack candidate_commit is not an exact commit identity"
  end

  def test_closeout_rejects_unknown_default_reachability_or_tree_parity
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("reachability")["tree_parity"] = "unknown"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "aggregate reachability tree_parity does not match per-target merge states"
  end

  def test_closeout_rejects_merge_during_a_freeze_conflict
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("merge")["freeze_state"] = "conflict"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "target #{target['id']} merged during a freeze or phase conflict"
  end

  def test_closeout_requires_applicable_merges_to_be_complete
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("merge")["status"] = "authorized"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "target #{target['id']} merge disposition is not terminal"
  end

  def test_closeout_requires_replayable_explicit_merge_authority_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("merge")["authority_evidence"] = nil

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "target #{target['id']} merged without authority evidence"
  end

  def test_validated_ledger_regenerates_the_append_only_tracker_matrix
    generator = build_generator
    ledger = complete_ledger(generator)
    validator = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    )

    assert_empty validator.errors

    tracker = FleetValidation::TrackerRenderer.new(ledger).render

    assert_includes tracker, "<!-- fleet-validation-closeout:fleet-test-pack -->"
    assert_includes tracker, "Verdict: PASS"
    assert_equal 13, (tracker.lines.count { |line| line.match?(/\| (hard_gate|soft_track) \|/) })
    assert_includes tracker, "## Required release paths"
    assert_includes tracker, "## Blocker ownership"
    assert_includes tracker, "Promotion recommendation: recommend"
  end

  def test_tracker_derives_partial_and_blocked_verdicts_from_the_ledger
    generator = build_generator
    partial = complete_ledger(generator)
    partial.fetch("inventory").find { |item| item["tier"] == "soft_track" }["result"] = "blocked"
    blocked = complete_ledger(generator)
    blocked.fetch("inventory").find { |item| item["tier"] == "hard_gate" }["result"] = "blocked"

    assert_includes FleetValidation::TrackerRenderer.new(partial).render, "Verdict: PARTIAL"
    assert_includes FleetValidation::TrackerRenderer.new(blocked).render, "Verdict: BLOCKED"
  end

  def test_check_and_preflight_waivers_render_partial
    generator = build_generator
    check_waiver = complete_ledger(generator)
    target = check_waiver.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    check = target.fetch("checks").fetch("hosted_ci")
    check["status"] = "waived"
    check["waiver"] = {
      "gate" => "#{target['id']}:hosted_ci",
      "authority" => "maintainer",
      "evidence_url" => "https://example.invalid/waiver",
      "reason" => "sanitized"
    }
    preflight_waiver = complete_ledger(generator)
    preflight_waiver.fetch("preflight").merge!(
      "status" => "waived",
      "waiver" => {
        "gate" => "release_ci",
        "authority" => "maintainer",
        "evidence_url" => "https://example.invalid/waiver",
        "reason" => "sanitized"
      }
    )
    preflight_waiver.fetch("preflight").fetch("release_ci")["status"] = "waived"

    assert_includes FleetValidation::TrackerRenderer.new(check_waiver).render, "Verdict: PARTIAL"
    assert_includes FleetValidation::TrackerRenderer.new(preflight_waiver).render, "Verdict: PARTIAL"
  end

  def test_promotion_recommendation_is_rejected_while_a_blocker_remains_active
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = [
      {
        "id" => "sanitized-blocker",
        "status" => "open",
        "public_summary" => "Sanitized active blocker",
        "owner" => { "issue_url" => "https://example.invalid/issues/1" },
        "disposition" => nil
      }
    ]

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "promotion cannot be recommended while release blockers remain"
  end

  def test_nested_hard_gate_failure_blocks_promotion
    generator = build_generator
    check_failure = complete_ledger(generator)
    check_failure.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
                 .fetch("checks").fetch("hosted_ci")["status"] = "blocked"
    regression = complete_ledger(generator)
    regression.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
              .fetch("baseline")["classification"] = "candidate_regression"

    [check_failure, regression].each do |ledger|
      errors = FleetValidation::LedgerValidator.new(
        ledger,
        inventory: generator.lifecycle_inventory,
        required_paths: generator.required_paths,
        closeout: true
      ).errors

      assert_includes errors, "promotion cannot be recommended while release blockers remain"
      assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: BLOCKED"
    end
  end

  def test_blocked_hard_gate_outcomes_require_owned_blocker_references
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target["result"] = "blocked"
    target.fetch("checks").fetch("hosted_ci")["status"] = "blocked"
    ledger.fetch("tracker")["promotion"] = "hold"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("blocked result has no owned blocker reference") })
    assert(errors.any? { |error| error.include?("blocked check hosted_ci has no owned blocker reference") })
  end

  def test_waived_hard_gate_and_check_require_structured_waiver_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target["result"] = "waived"
    target.fetch("checks").fetch("hosted_ci")["status"] = "waived"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("waived result is missing structured waiver evidence") })
    assert(errors.any? { |error| error.include?("waived check hosted_ci is missing structured waiver evidence") })
  end

  def test_ledger_cli_validates_and_renders_the_tracker_from_one_file
    generator = build_generator
    Dir.mktmpdir do |directory|
      ledger_path = File.join(directory, "ledger.json")
      tracker_path = File.join(directory, "tracker.md")
      File.write(ledger_path, JSON.pretty_generate(complete_ledger(generator)))

      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        VALIDATOR,
        "--manifest", MANIFEST,
        "--ledger", ledger_path,
        "--expected-candidate", "v17.0.0.rc.12",
        "--render-tracker", tracker_path
      )

      assert status.success?, stderr
      assert_includes stdout, "VALID fleet result ledger"
      assert File.exist?(tracker_path)
    end
  end

  def test_ledger_cli_reports_schema_errors_without_running_crashing_semantic_validation
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory")[0] = "malformed"

    Dir.mktmpdir do |directory|
      ledger_path = File.join(directory, "ledger.json")
      File.write(ledger_path, JSON.pretty_generate(ledger))
      _stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        VALIDATOR,
        "--ledger",
        ledger_path,
        "--expected-candidate",
        "v17.0.0.rc.12"
      )

      refute status.success?
      assert_includes stderr, "$.inventory[0] has invalid type"
      refute_includes stderr, "NoMethodError"
    end
  end

  def test_ledger_cli_requires_an_external_expected_candidate
    generator = build_generator
    Dir.mktmpdir do |directory|
      ledger_path = File.join(directory, "ledger.json")
      File.write(ledger_path, JSON.pretty_generate(complete_ledger(generator)))

      _stdout, stderr, status = Open3.capture3(RbConfig.ruby, VALIDATOR, "--manifest", MANIFEST, "--ledger", ledger_path)

      refute status.success?
      assert_includes stderr, "missing argument: --expected-candidate"
    end
  end

  def test_closeout_requires_terminal_tracker_state_and_posted_comment_identity
    generator = build_generator
    pending = complete_ledger(generator)
    pending.fetch("tracker").merge!("status" => "pending", "comment_url" => nil)
    posted = complete_ledger(generator)
    posted.fetch("tracker").merge!("status" => "posted", "comment_url" => nil)

    pending_errors = FleetValidation::LedgerValidator.new(
      pending,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors
    posted_errors = FleetValidation::LedgerValidator.new(
      posted,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes pending_errors, "tracker closeout status is not ready or posted"
    assert_includes posted_errors, "posted tracker closeout is missing comment_url"
  end

  def test_result_ledger_schema_closes_public_blocker_and_review_app_shapes
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      schema = JSON.parse(File.read(File.join(directory, "result-ledger.schema.json")))

      assert_equal false, schema.dig("properties", "blockers", "items", "additionalProperties")
      assert_includes schema.dig("properties", "blockers", "items", "required"), "disposition"
      assert_includes schema.dig("properties", "required_paths", "items", "required"), "blocker_id"
      assert_includes schema.dig("properties", "inventory", "items", "required"), "maker_id"
      assert_equal(
        %w[configured_runnable configured_broken not_configured unknown],
        schema.dig(
          "properties", "inventory", "items", "properties", "review_app", "properties", "state", "enum"
        )
      )
    end
  end

  def test_schema_validator_rejects_unknown_fields_and_invalid_enums
    generator = build_generator
    ledger = generator.ledger_template
    ledger["unexpected"] = true
    ledger.fetch("inventory").first.fetch("review_app")["state"] = "invented"

    errors = FleetValidation::SchemaValidator.new(generator.ledger_schema).errors(ledger)

    assert_includes errors, "$ has unsupported field unexpected"
    assert_includes errors, "$.inventory[0].review_app.state is not an allowed value"
  end

  def test_ledger_template_has_exact_package_check_baseline_and_review_app_evidence_slots
    target = build_generator.ledger_template.fetch("inventory").find { |item| item["tier"] == "hard_gate" }

    assert_equal [], target.fetch("package_locks")
    assert_nil target.fetch("maker_id")
    assert_equal(
      %w[build hosted_ci install local_smoke review test],
      target.fetch("checks").keys.sort
    )
    assert_equal %w[classification evidence head_commit waiver], target.fetch("baseline").keys.sort
    assert_equal %w[blocker_id deployed_smoke evidence head_commit state waiver], target.fetch("review_app").keys.sort
  end

  def test_closeout_requires_exact_retained_package_lock_versions_and_sources
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }["package_locks"] = []

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "1 hard-gate target(s) are missing retained package lock evidence"
  end

  def test_core_generator_gate_tracks_the_published_cli_version
    core = build_generator.lifecycle_inventory.find do |target|
      target.fetch("id") == "react-on-rails-generator-install-smoke"
    end

    expected = [
      { "ecosystem" => "gem", "name" => "react_on_rails" },
      { "ecosystem" => "npm", "name" => "react-on-rails" },
      { "ecosystem" => "npm", "name" => "create-react-on-rails-app" },
      { "ecosystem" => "gem", "name" => "react_on_rails_pro" },
      { "ecosystem" => "npm", "name" => "react-on-rails-pro" },
      { "ecosystem" => "npm", "name" => "react-on-rails-pro-node-renderer" },
      { "ecosystem" => "npm", "name" => "react-on-rails-rsc" }
    ]

    assert_equal expected, core.fetch("packages")
  end

  def test_closeout_requires_every_manifest_package_in_the_retained_lock_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" && item["package_locks"].length > 1 }
    target.fetch("package_locks").pop

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 hard-gate target(s) are missing retained package lock evidence"
  end

  def test_report_only_targets_require_retained_package_lock_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory").find { |item| item["work_mode"] == "report_only" }["package_locks"] = []

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 inventory target(s) are missing retained package lock evidence"
  end

  def test_resolved_product_versions_must_match_the_selected_candidate
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("pack").fetch("resolved_packages").each do |package|
      next if package["name"] == "react-on-rails-rsc"

      package["version"] = package["ecosystem"] == "gem" ? "17.0.0.rc.11" : "17.0.0-rc.11"
    end
    ledger.fetch("inventory").each do |item|
      item.fetch("package_locks").each do |package|
        next if package["name"] == "react-on-rails-rsc"
        next unless %w[
          react_on_rails react_on_rails_pro react-on-rails create-react-on-rails-app
          react-on-rails-pro react-on-rails-pro-node-renderer
        ].include?(package["name"])

        package["version"] = package["ecosystem"] == "gem" ? "17.0.0.rc.11" : "17.0.0-rc.11"
      end
    end

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "resolved product package versions do not match candidate v17.0.0.rc.12"
  end

  def test_closeout_rejects_retained_lock_versions_that_do_not_match_the_resolved_snapshot
    generator = build_generator
    ledger = complete_ledger(generator)
    lock = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
                 .fetch("package_locks").first
    lock["version"] = "0.0.1"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes(
      errors,
      "1 hard-gate target(s) retain package versions or sources outside the resolved release snapshot"
    )
  end

  def test_closeout_rejects_retained_lock_sources_that_do_not_match_the_resolved_snapshot
    generator = build_generator
    ledger = complete_ledger(generator)
    lock = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
                 .fetch("package_locks").first
    lock["source"] = "git-or-path-override"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 hard-gate target(s) retain package versions or sources outside the resolved release snapshot"
  end

  def test_closeout_rejects_nonterminal_work_and_blank_result_or_baseline_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").first
    target["work_state"] = "not_started"
    target["evidence"] = nil
    target.fetch("baseline")["evidence"] = nil

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 inventory target(s) are unknown or nonterminal"
  end

  def test_closeout_rejects_a_blocked_work_state_with_a_passing_result
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }["work_state"] = "blocked"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 inventory target(s) have inconsistent work-state/result combinations"
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: BLOCKED"
  end

  def test_closeout_requires_structured_baseline_waiver_and_renders_partial
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target.fetch("baseline").merge!("classification" => "waived", "waiver" => nil)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("waived baseline is missing structured waiver evidence") })
    target.fetch("baseline")["waiver"] = {
      "gate" => "#{target['id']}:baseline",
      "authority" => "maintainer",
      "evidence_url" => "https://example.invalid/baseline-waiver",
      "reason" => "sanitized"
    }
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: PARTIAL"
  end

  def test_unwaived_baseline_defect_blocks_promotion_and_structured_waiver_renders_partial
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("baseline").merge!(
      "classification" => "baseline_defect",
      "evidence" => "fresh default branch reproduces the failure",
      "waiver" => nil
    )

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("baseline defect is missing structured waiver evidence") })
    assert_includes errors, "promotion cannot be recommended while release blockers remain"

    target.fetch("baseline")["waiver"] = {
      "gate" => "#{target['id']}:baseline",
      "authority" => "maintainer",
      "evidence_url" => "https://example.invalid/baseline-defect-waiver",
      "reason" => "Proven unrelated to the candidate"
    }
    waived_errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_empty waived_errors
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: PARTIAL"
  end

  def test_blocked_closeout_does_not_require_merge_or_post_merge_reachability
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target.merge!("work_state" => "blocked", "result" => "blocked", "blocker_id" => "owned-blocker")
    target.fetch("checks").each_value do |check|
      check.merge!("status" => "blocked", "blocker_id" => "owned-blocker")
    end
    ledger["blockers"] = [
      {
        "id" => "owned-blocker",
        "status" => "open",
        "public_summary" => "Sanitized release blocker",
        "owner" => { "issue_url" => "https://example.invalid/issues/1" },
        "disposition" => nil
      }
    ]
    ledger.fetch("inventory").select { |item| item["work_mode"] == "mutation" }.each do |item|
      item.fetch("merge").merge!(
        "status" => "blocked",
        "authority" => "none",
        "authority_evidence" => nil,
        "merge_commit" => nil,
        "evidence" => "release blocked before merge"
      )
      item.fetch("reachability").merge!("default_branch" => "pending", "tree_parity" => "pending")
    end
    ledger.fetch("merge")["status"] = "blocked"
    ledger.fetch("reachability").merge!("default_branch" => "blocked", "tree_parity" => "blocked")
    ledger.fetch("tracker")["promotion"] = "blocked"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    refute(errors.any? { |error| error.match?(/merge status|reachability|base is missing/) }, errors.join("\n"))
    assert_includes FleetValidation::TrackerRenderer.new(ledger).render, "Verdict: BLOCKED"
  end

  def test_blocked_closeout_rejects_an_unauthorized_recorded_merge
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.merge!("work_state" => "blocked", "result" => "blocked", "blocker_id" => "owned-blocker")
    ledger["blockers"] = [
      {
        "id" => "owned-blocker",
        "status" => "open",
        "public_summary" => "Sanitized release blocker",
        "owner" => { "issue_url" => "https://example.invalid/issues/1" },
        "disposition" => nil
      }
    ]
    target.fetch("merge").merge!(
      "authority" => "none",
      "authority_evidence" => nil,
      "freeze_state" => "frozen",
      "status" => "merged"
    )
    ledger.fetch("tracker")["promotion"] = "blocked"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "target #{target['id']} merged without explicit authority"
    assert_includes errors, "target #{target['id']} merged without authority evidence"
    assert_includes errors, "target #{target['id']} merged during a freeze or phase conflict"
  end

  def test_partial_merge_closeout_requires_proofs_only_for_the_lanes_that_landed
    generator = build_generator
    ledger = complete_ledger(generator)
    mutable = ledger.fetch("inventory").select { |item| item["work_mode"] == "mutation" }
    merged = mutable.first
    blocked = mutable.last
    mutable.each do |item|
      item["merge"] = {
        "status" => "blocked",
        "authority" => "none",
        "authority_evidence" => nil,
        "freeze_state" => "clear",
        "merge_commit" => nil,
        "evidence" => "public-safe merge disposition"
      }
      item.fetch("reachability").merge!(
        "default_branch" => "pending",
        "default_commit" => nil,
        "default_evidence" => nil,
        "tree_parity" => "pending",
        "tree" => nil,
        "tree_evidence" => nil
      )
    end
    merged.fetch("merge").merge!(
      "status" => "merged",
      "authority" => "auto_merge_when_gates_pass",
      "authority_evidence" => "trusted batch goal",
      "merge_commit" => "cccccccccccccccccccccccccccccccccccccccc",
      "evidence" => "public-safe merge evidence"
    )
    merged.fetch("reachability").merge!(
      "default_branch" => "passed",
      "default_commit" => "cccccccccccccccccccccccccccccccccccccccc",
      "default_evidence" => "public-safe reachability",
      "tree_parity" => "passed",
      "tree" => "dddddddddddddddddddddddddddddddddddddddd",
      "tree_evidence" => "public-safe tree parity"
    )
    blocked.merge!("work_state" => "blocked", "result" => "blocked", "blocker_id" => "owned-blocker")
    blocked.fetch("checks").each_value do |check|
      check.merge!("status" => "blocked", "blocker_id" => "owned-blocker")
    end
    ledger["blockers"] = [
      {
        "id" => "owned-blocker",
        "status" => "open",
        "public_summary" => "Sanitized release blocker",
        "owner" => { "issue_url" => "https://example.invalid/issues/1" },
        "disposition" => nil
      }
    ]
    ledger.fetch("merge")["status"] = "partial"
    ledger.fetch("reachability").merge!("default_branch" => "partial", "tree_parity" => "partial")
    ledger.fetch("tracker")["promotion"] = "blocked"

    schema_errors = FleetValidation::SchemaValidator.new(generator.ledger_schema).errors(ledger)
    semantic_errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_empty schema_errors
    assert_empty semantic_errors
  end

  def test_closeout_binds_each_target_audit_base_to_its_reviewed_base
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("bases").merge!(
      "audit" => "cccccccccccccccccccccccccccccccccccccccc",
      "reviewed" => "dddddddddddddddddddddddddddddddddddddddd"
    )

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("audit base does not match reviewed base") })
  end

  def test_same_pack_id_cannot_be_reused_for_a_different_release_snapshot
    Dir.mktmpdir do |directory|
      build_generator(release_selector: "v17.0.0.rc.12").write_pack(directory)
      old_index = File.read(File.join(directory, "INDEX.md"))
      regenerated = build_generator(release_selector: "v17.0.0.rc.13")

      error = assert_raises(FleetValidation::ManifestError) { regenerated.write_pack(directory) }
      assert_includes error.message, "existing result ledger belongs to a different release snapshot"
      assert_equal old_index, File.read(File.join(directory, "INDEX.md"))
    end
  end

  def test_dynamic_selector_pack_cannot_reuse_a_resolved_candidate_barrier
    Dir.mktmpdir do |directory|
      generator = build_generator
      generator.write_pack(directory)
      ledger_path = File.join(directory, "result-ledger.json")
      ledger = JSON.parse(File.read(ledger_path))
      ledger.fetch("pack")["candidate"] = "v17.0.0.rc.12"
      ledger.fetch("preflight")["app_work_allowed"] = true
      File.write(ledger_path, JSON.pretty_generate(ledger))
      old_index = File.read(File.join(directory, "INDEX.md"))

      error = assert_raises(FleetValidation::ManifestError) { generator.write_pack(directory) }

      assert_includes error.message, "resolved dynamic candidate cannot be safely reused"
      assert_equal old_index, File.read(File.join(directory, "INDEX.md"))
    end
  end

  def test_external_expected_candidate_does_not_override_a_pinned_selector
    generator = build_generator(release_selector: "v17.0.0.rc.11")
    ledger = complete_ledger(generator)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      expected_snapshot_fingerprint: generator.snapshot_fingerprint,
      closeout: true
    ).errors

    assert_includes errors, "candidate mismatch: pinned selector v17.0.0.rc.11, got v17.0.0.rc.12"
  end

  def test_closeout_rejects_a_ledger_from_a_different_manifest_snapshot
    generator = build_generator
    ledger = complete_ledger(generator)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_snapshot_fingerprint: "different-fingerprint",
      closeout: true
    ).errors

    assert_includes errors, "pack snapshot_fingerprint does not match the current manifest"
  end

  def test_closeout_binds_required_paths_to_manifest_evidence_sources
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger.fetch("required_paths").first["evidence_source"] = "unrelated-source"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("evidence_source does not match manifest") })
  end

  def test_same_pack_id_cannot_be_reused_after_manifest_policy_changes
    Dir.mktmpdir do |directory|
      build_generator(release_selector: "v17.0.0.rc.12").write_pack(directory)
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      manifest.fetch("defaults")["build"] = "changed sanitized build command"
      manifest_path = File.join(directory, "changed-manifest.yml")
      File.write(manifest_path, YAML.dump(manifest))
      regenerated = build_generator(
        manifest_path:,
        release_selector: "v17.0.0.rc.12"
      )

      error = assert_raises(FleetValidation::ManifestError) { regenerated.write_pack(directory) }
      assert_includes error.message, "existing result ledger belongs to a different release snapshot"
    end
  end

  def test_closeout_requires_per_target_reachability_and_tree_parity_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }
    target.fetch("reachability").merge!("default_evidence" => nil, "tree_evidence" => nil)

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("default-branch reachability evidence is incomplete") })
    assert(errors.any? { |error| error.include?("tree-parity evidence is incomplete") })
  end

  def test_validation_only_core_gate_does_not_require_merge_base_or_reachability_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    core = ledger.fetch("inventory").find { |item| item["work_mode"] == "validation_only" }
    core.fetch("bases").merge!("audit" => nil, "reviewed" => nil, "current" => nil, "reconciliation" => "pending")
    core.fetch("reachability").merge!(
      "default_branch" => "pending",
      "default_commit" => nil,
      "default_evidence" => nil,
      "tree_parity" => "pending",
      "tree" => nil,
      "tree_evidence" => nil
    )

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    refute(errors.any? { |error| error.include?(core.fetch("id")) }, errors.join("\n"))
  end

  def test_recorded_merges_retain_base_and_reachability_proofs_when_another_lane_blocks
    generator = build_generator
    ledger = complete_ledger(generator)
    ledger["blockers"] = [
      {
        "id" => "later-blocker",
        "status" => "open",
        "public_summary" => "Another lane blocked after merges",
        "owner" => { "issue_url" => "https://example.invalid/issues/later" },
        "disposition" => nil
      }
    ]
    ledger.fetch("tracker")["promotion"] = "blocked"
    ledger.fetch("inventory").select { |item| item["work_mode"] == "mutation" }.each do |item|
      item.fetch("bases").merge!("audit" => nil, "reviewed" => nil, "current" => nil)
      item.fetch("reachability").merge!(
        "default_branch" => "pending",
        "default_commit" => nil,
        "default_evidence" => nil,
        "tree_parity" => "pending",
        "tree" => nil,
        "tree_evidence" => nil
      )
    end

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("audit base is missing or not an exact commit identity") })
    assert(errors.any? { |error| error.include?("default-branch reachability evidence is incomplete") })
  end

  def test_report_only_tracks_retain_post_preflight_work_start_ordering
    generator = build_generator
    missing = complete_ledger(generator)
    missing.fetch("inventory").find { |item| item["work_mode"] == "report_only" }["work_started_at"] = nil
    early = complete_ledger(generator)
    early.fetch("inventory").find { |item| item["work_mode"] == "report_only" }["work_started_at"] =
      "2026-07-18T09:59:00Z"

    missing_errors = FleetValidation::LedgerValidator.new(
      missing,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors
    early_errors = FleetValidation::LedgerValidator.new(
      early,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(missing_errors.any? { |error| error.include?("missing replayable barrier/work-start ordering evidence") })
    assert(early_errors.any? { |error| error.include?("started before the preflight barrier opened") })
  end

  def test_closeout_requires_terminal_install_build_test_smoke_ci_and_review_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target.fetch("checks").fetch("hosted_ci")["status"] = "unknown"

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      closeout: true
    ).errors

    assert_includes errors, "1 hard-gate target(s) check evidence is not bound to its immutable current head"
  end

  def test_hard_gate_checks_must_match_the_immutable_current_head
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }
    target["revisions"] = {
      "audit" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "reviewed" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "current" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "reconciliation" => "passed"
    }
    target.fetch("checks").each_value do |check|
      check["head_commit"] = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    end

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert(errors.any? { |error| error.include?("check evidence is not bound to its immutable current head") })
  end

  def test_report_only_checks_must_have_terminal_current_head_evidence
    generator = build_generator
    ledger = complete_ledger(generator)
    target = ledger.fetch("inventory").find { |item| item["work_mode"] == "report_only" }
    target.fetch("checks").each_value do |check|
      check.merge!("status" => "unknown", "head_commit" => nil, "evidence" => nil)
    end

    errors = FleetValidation::LedgerValidator.new(
      ledger,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      closeout: true
    ).errors

    assert_includes errors, "1 report-only target(s) have unknown or stale check evidence"
  end

  def test_sanitized_rc12_replay_exercises_inventory_barriers_ownership_and_tracker_regeneration
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, RC12_REPLAY)

    assert status.success?, stderr
    assert_includes stdout, "hard_gates=8"
    assert_includes stdout, "soft_tracks=5"
    assert_includes stdout, "required_path=webpack-rsc-production:scheduled"
    assert_includes stdout, "unowned_blockers_rejected=6"
    assert_includes stdout, "tracker_rows=13"
    assert_includes stdout, "tracker_verdict=PARTIAL"
    assert_includes stdout, "SANITIZED_RC12_REPLAY_PASS"
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
    assert_includes pack, "create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-standard --standard"
    assert_includes pack, "create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-pro`"
    assert_includes pack, "create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-rsc --rsc"
    assert_includes pack, "independently resolved RSC version only in the RSC app"
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

  def test_index_launches_preflight_before_makers_and_closeout_after_ledger_validation
    Dir.mktmpdir do |directory|
      build_generator.write_pack(directory)
      index = File.read(File.join(directory, "INDEX.md"))

      assert_includes index, "[PREFLIGHT.md](PREFLIGHT.md)"
      assert_includes index, "[REPORT-ONLY.md](REPORT-ONLY.md)"
      assert_includes index, "[CLOSEOUT.md](CLOSEOUT.md)"
      assert_includes index, "`result-ledger.json`"
      assert_includes index, "Do not start the app mutation prompts before `APP_WORK_ALLOWED`"
      assert_operator index.index("Start prompt coordinator 1"), :<, index.index("[PREFLIGHT.md](PREFLIGHT.md)")
      assert_operator index.index("[PREFLIGHT.md](PREFLIGHT.md)"), :<, index.index("Start the remaining prompt coordinators")
      refute_includes index, "Start all 6 prompt coordinators simultaneously after the snapshot exists"
    end
  end

  def test_core_matrix_gate_is_always_assigned_to_coordinator_one
    (4..8).each do |prompt_count|
      generator = build_generator(prompt_count:)
      first_targets = generator.send(:ordered_assignments).first.fetch(:targets)

      assert(
        first_targets.any? { |target| target["kind"] == "core" },
        "expected core gate in coordinator 1 with #{prompt_count} prompts"
      )
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

  def test_regenerating_the_same_pack_preserves_its_existing_result_ledger
    Dir.mktmpdir do |directory|
      generator = build_generator(release_selector: "v17.0.0.rc.12")
      generator.write_pack(directory)
      ledger_path = File.join(directory, "result-ledger.json")
      ledger = JSON.parse(File.read(ledger_path))
      ledger.fetch("pack")["candidate"] = "v17.0.0.rc.12"
      File.write(ledger_path, JSON.pretty_generate(ledger))

      generator.write_pack(directory)

      assert_equal "v17.0.0.rc.12", JSON.parse(File.read(ledger_path)).dig("pack", "candidate")
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

  def test_strips_trailing_separators_from_stable_target_ids
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      manifest.fetch("repos").find { |repo| repo["tier"] == "hard_gate" }["name"] = "owner/example!"
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      pack = build_generator(manifest_path:).render_pack

      assert_includes pack, "- owner/example!: owner-example"
      refute_includes pack, "fallback_claim_target_template: adhoc:fleet-RESOLVED_TAG-owner-example-"
    end
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

  def test_rejects_a_non_mapping_repo_entry
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      manifest.fetch("repos")[0] = "not-a-repo"
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "repos[0] must be a mapping", error.message
    end
  end

  def test_rejects_an_unsupported_repository_tier
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      manifest.fetch("repos").first["tier"] = "hard-gate"
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "repos[0] tier must be hard_gate or soft_track", error.message
    end
  end

  def test_rejects_malformed_soft_track_package_entries
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      soft_track = manifest.fetch("repos").find { |repo| repo["tier"] == "soft_track" }
      soft_track["packages"] = ["react-on-rails"]
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      index = manifest.fetch("repos").index(soft_track)
      assert_equal "repos[#{index}].packages[0] must name an ecosystem and package", error.message
    end
  end

  def test_rejects_a_manifest_without_required_lifecycle_paths
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      manifest.delete("lifecycle")
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "lifecycle.required_paths must be a nonempty array", error.message
    end
  end

  def test_lifecycle_invariant_families_fail_closed_table
    generator = build_generator
    cases = [
      {
        name: "exact snapshot identity",
        mutate: ->(ledger) { ledger.fetch("pack")["candidate_commit"] = nil },
        expected: "app work started before APP_WORK_ALLOWED"
      },
      {
        name: "resolved artifact snapshot",
        mutate: ->(ledger) { ledger.fetch("pack")["resolved_packages"] = [] },
        expected: "app work started before APP_WORK_ALLOWED"
      },
      {
        name: "transition ordering",
        mutate: lambda do |ledger|
          ledger.fetch("inventory").find { |item| item["work_mode"] == "mutation" }["work_started_at"] =
            "2026-07-18T09:59:00Z"
        end,
        expected: "started before the preflight barrier opened"
      },
      {
        name: "terminal review evidence",
        mutate: lambda do |ledger|
          ledger.fetch("inventory").find { |item| item["tier"] == "hard_gate" }.fetch("review_app").merge!(
            "state" => "configured_runnable",
            "deployed_smoke" => "pending"
          )
        end,
        expected: "review-app smoke is not terminal"
      },
      {
        name: "complete inventory",
        mutate: ->(ledger) { ledger.fetch("inventory").pop },
        expected: "inventory missing target"
      },
      {
        name: "restart equivalence",
        mutate: lambda do |ledger|
          ledger.fetch("preflight").fetch("capabilities")["restart_handoff"] = nil
        end,
        expected: "app work started before APP_WORK_ALLOWED"
      }
    ]

    cases.each do |test_case|
      ledger = complete_ledger(generator)
      test_case.fetch(:mutate).call(ledger)
      errors = FleetValidation::LedgerValidator.new(
        ledger,
        inventory: generator.lifecycle_inventory,
        required_paths: generator.required_paths,
        expected_candidate: "v17.0.0.rc.12",
        expected_snapshot_fingerprint: generator.snapshot_fingerprint,
        closeout: true
      ).errors

      assert(
        errors.any? { |error| error.include?(test_case.fetch(:expected)) },
        "#{test_case.fetch(:name)} did not fail closed:\n#{errors.join("\n")}"
      )
    end

    read_only = complete_ledger(generator)
    read_only.fetch("preflight")["app_work_allowed"] = false
    read_only.fetch("inventory").select { |item| item["work_mode"] == "mutation" }.each do |item|
      item.merge!("work_state" => "not_started", "work_started_at" => nil)
    end
    core = read_only.fetch("inventory").find { |item| item["work_mode"] == "validation_only" }
    core["work_state"] = "running"
    errors = FleetValidation::LedgerValidator.new(
      read_only,
      inventory: generator.lifecycle_inventory,
      required_paths: generator.required_paths,
      expected_candidate: "v17.0.0.rc.12",
      expected_snapshot_fingerprint: generator.snapshot_fingerprint
    ).errors

    refute_includes errors, "app work started before APP_WORK_ALLOWED"
  end

  def test_rejects_a_hard_gate_missing_a_required_field
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      hard_gate = manifest.fetch("repos").find { |repo| repo["tier"] == "hard_gate" }
      hard_gate.delete("name")
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "repos[0] hard gate is missing name", error.message
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

  def test_rejects_an_empty_stable_target_id
    Dir.mktmpdir do |directory|
      manifest = YAML.safe_load_file(MANIFEST, aliases: false)
      hard_gate = manifest.fetch("repos").find { |repo| repo["tier"] == "hard_gate" }
      hard_gate["name"] = "!!!"
      manifest_path = File.join(directory, "fleet.yml")
      File.write(manifest_path, YAML.dump(manifest))

      error = assert_raises(FleetValidation::ManifestError) do
        build_generator(manifest_path:)
      end

      assert_equal "target names must have non-empty stable IDs", error.message
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
