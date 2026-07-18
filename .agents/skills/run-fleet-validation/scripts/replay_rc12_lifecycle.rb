#!/usr/bin/env ruby
# frozen_string_literal: true

require "tmpdir"
require_relative "generate_prompts"

module FleetValidation
  module RC12Replay
    module_function

    FIXTURE = File.expand_path("../fixtures/rc12-sanitized.yml", __dir__)
    CANDIDATE = "v17.0.0.rc.12"

    def run
      generator = Generator.new(
        manifest_path: FIXTURE,
        prompt_count: 6,
        machines: %w[local m1],
        release_selector: CANDIDATE,
        pack_id: "rc12-sanitized"
      )
      ledger = completed_ledger(generator)
      ledger["blockers"] = six_unowned_blockers
      rejected = validator(generator, ledger).errors.grep(/has no durable owner/).length
      raise "expected six unowned blockers to fail closeout" unless rejected == 6

      ledger.fetch("blockers").each_with_index do |blocker, index|
        blocker["status"] = "deferred"
        blocker["owner"] = { "issue_url" => "https://example.invalid/issues/#{index + 1}" }
      end
      ledger.fetch("tracker")["promotion"] = "hold"
      final_errors = validator(generator, ledger).errors
      raise "recovered ledger did not validate: #{final_errors.join('; ')}" unless final_errors.empty?

      tracker = TrackerRenderer.new(ledger).render
      tracker_rows = tracker.lines.count { |line| line.match?(/\| (hard_gate|soft_track) \|/) }
      raise "tracker row mismatch" unless tracker_rows == 13
      raise "tracker verdict mismatch" unless tracker.include?("Verdict: PARTIAL")

      Dir.mktmpdir do |directory|
        generator.write_pack(directory)
        raise "lifecycle artifact missing" unless File.exist?(File.join(directory, "CLOSEOUT.md"))
      end

      hard_gates = generator.lifecycle_inventory.count { |target| target["tier"] == "hard_gate" }
      soft_tracks = generator.lifecycle_inventory.count { |target| target["tier"] == "soft_track" }
      puts "hard_gates=#{hard_gates}"
      puts "soft_tracks=#{soft_tracks}"
      puts "required_path=webpack-rsc-production:scheduled"
      puts "unowned_blockers_rejected=#{rejected}"
      puts "tracker_rows=#{tracker_rows}"
      puts "tracker_verdict=PARTIAL"
      puts "SANITIZED_RC12_REPLAY_PASS"
      0
    rescue ManifestError, RuntimeError => e
      warn "SANITIZED_RC12_REPLAY_FAIL: #{e.message}"
      1
    end

    def validator(generator, ledger)
      LedgerValidator.new(
        ledger,
        inventory: generator.lifecycle_inventory,
        required_paths: generator.required_paths,
        expected_candidate: CANDIDATE,
        closeout: true
      )
    end

    def completed_ledger(generator)
      ledger = generator.ledger_template
      ledger.fetch("pack").merge!(
        "candidate" => CANDIDATE,
        "candidate_commit" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "policy_commit" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "tracker_mode" => "strict-rc",
        "resolved_packages" => generator.lifecycle_inventory.flat_map { |target| target.fetch("packages") }
                                      .uniq { |package| [package["ecosystem"], package["name"]] }
                                      .map { |package| package.merge("version" => "1.0.0", "source" => "registry") }
      )
      ledger.fetch("preflight")["status"] = "passed"
      ledger.fetch("preflight")["app_work_allowed"] = true
      ledger.fetch("preflight")["opened_at"] = "2026-07-18T10:00:00Z"
      %w[release_ci artifacts generator_matrix].each do |gate|
        ledger.fetch("preflight").fetch(gate).merge!("status" => "passed", "evidence" => "public-safe evidence")
      end
      capabilities = ledger.fetch("preflight").fetch("capabilities")
      capabilities.transform_values! { "passed" }
      capabilities["restart_handoff"] = "sanitized restart-safe handoff"
      complete_inventory(ledger, generator)
      ledger.fetch("required_paths").each do |path|
        path.merge!("status" => "passed", "lane" => "sanitized-lane", "evidence" => "public-safe evidence")
      end
      ledger.fetch("audit").merge!(
        "status" => "passed",
        "checker" => "independent-checker",
        "maker_ids" => ["maker-1"],
        "base_commit" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
      )
      ledger.fetch("merge").merge!(
        "authority" => "auto_merge_when_gates_pass",
        "authority_evidence" => "sanitized trusted batch goal",
        "freeze_state" => "clear",
        "status" => "merged",
        "reviewed_base_commit" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "current_base_commit" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "base_reconciliation" => "passed"
      )
      ledger.fetch("reachability").merge!("default_branch" => "passed", "tree_parity" => "passed")
      ledger.fetch("tracker").merge!(
        "status" => "ready",
        "comment_url" => "https://example.invalid/tracker",
        "promotion" => "recommend"
      )
      ledger
    end

    def complete_inventory(ledger, generator)
      ledger.fetch("inventory").each do |item|
        item.merge!(
          "work_state" => "finished",
          "result" => item["tier"] == "hard_gate" ? "passed" : "reported",
          "work_started_at" => "2026-07-18T10:01:00Z",
          "evidence" => "public-safe evidence"
        )
        expected = generator.lifecycle_inventory.find { |target| target["id"] == item["id"] }
        item["package_locks"] = expected.fetch("packages").map do |package|
          package.merge("version" => "1.0.0", "source" => "registry")
        end
        item.fetch("checks").each_value do |check|
          check.merge!("status" => "passed", "evidence" => "public-safe evidence")
        end
        item.fetch("review_app").merge!(
          "state" => "not_configured",
          "evidence" => "not configured",
          "deployed_smoke" => "waived"
        )
        item.fetch("baseline").merge!(
          "classification" => "clean",
          "evidence" => "sanitized fresh-default control"
        )
        item.fetch("bases").merge!(
          "audit" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
          "reviewed" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
          "current" => "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
          "reconciliation" => "passed"
        )
        item.fetch("reachability").merge!(
          "default_branch" => "passed",
          "default_commit" => "cccccccccccccccccccccccccccccccccccccccc",
          "default_evidence" => "public-safe evidence",
          "tree_parity" => "passed",
          "tree" => "dddddddddddddddddddddddddddddddddddddddd",
          "tree_evidence" => "public-safe evidence"
        )
      end
    end

    def six_unowned_blockers
      (1..6).map do |number|
        {
          "id" => "blocker-#{number}",
          "status" => "open",
          "public_summary" => "Sanitized RC12 closeout blocker #{number}",
          "owner" => nil
        }
      end
    end
  end
end

exit FleetValidation::RC12Replay.run if $PROGRAM_NAME == __FILE__
