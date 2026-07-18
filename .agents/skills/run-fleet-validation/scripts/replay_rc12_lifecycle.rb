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
        blocker["disposition"] = {
          "gate" => blocker.fetch("id"),
          "authority" => "release-owner",
          "evidence_url" => "https://example.invalid/issues/#{index + 1}",
          "reason" => "Public-safe sanitized deferral"
        }
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
        "resolved_packages" => resolved_packages(generator)
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
        "evidence" => "sanitized independent audit report"
      )
      ledger.fetch("merge")["status"] = "merged"
      ledger.fetch("reachability").merge!("default_branch" => "passed", "tree_parity" => "passed")
      ledger.fetch("tracker").merge!(
        "status" => "ready",
        "comment_url" => "https://example.invalid/tracker",
        "promotion" => "recommend"
      )
      ledger
    end

    def resolved_packages(generator)
      generator.lifecycle_inventory.flat_map { |target| target.fetch("packages") }
               .uniq { |package| [package["ecosystem"], package["name"]] }
               .map do |package|
        product_names = LedgerValidator::PRODUCT_PACKAGES.fetch(package["ecosystem"], [])
        version = if product_names.include?(package["name"])
                    package["ecosystem"] == "gem" ? "17.0.0.rc.12" : "17.0.0-rc.12"
                  else
                    "1.0.0"
                  end
        package.merge("version" => version, "source" => "registry")
      end
    end

    def complete_inventory(ledger, generator)
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
          "evidence" => "sanitized fresh-default control"
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
            "authority_evidence" => "sanitized trusted batch goal",
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
    end

    def six_unowned_blockers
      (1..6).map do |number|
        {
          "id" => "blocker-#{number}",
          "status" => "open",
          "public_summary" => "Sanitized RC12 closeout blocker #{number}",
          "owner" => nil,
          "disposition" => nil
        }
      end
    end
  end
end

exit FleetValidation::RC12Replay.run if $PROGRAM_NAME == __FILE__
