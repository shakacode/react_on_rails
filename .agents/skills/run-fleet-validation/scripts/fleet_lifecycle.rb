# frozen_string_literal: true

require "json"
require "digest"

module FleetValidation
  class ManifestError < StandardError; end

  class Lifecycle
    CORE_INVENTORY_TARGET = {
      "id" => "react-on-rails-generator-install-smoke",
      "name" => "react_on_rails generator/install smoke",
      "headline" => "Monorepo generator and install smoke",
      "tier" => "hard_gate",
      "work_mode" => "mutation",
      "packages" => [
        { "ecosystem" => "gem", "name" => "react_on_rails" },
        { "ecosystem" => "npm", "name" => "react-on-rails" }
      ]
    }.freeze

    attr_reader :inventory, :required_paths

    def initialize(manifest:, pack_id:, release_selector:)
      @manifest = manifest
      @pack_id = pack_id
      @release_selector = release_selector
      @inventory = build_inventory
      @required_paths = build_required_paths
    end

    def write_artifacts(output_dir)
      File.write(File.join(output_dir, "LIFECYCLE.md"), render_lifecycle)
      File.write(File.join(output_dir, "PREFLIGHT.md"), render_preflight)
      File.write(File.join(output_dir, "REPORT-ONLY.md"), render_report_only)
      File.write(File.join(output_dir, "CLOSEOUT.md"), render_closeout)
      write_ledger(File.join(output_dir, "result-ledger.json"))
      File.write(File.join(output_dir, "result-ledger.schema.json"), "#{JSON.pretty_generate(schema)}\n")
    end

    def ledger_template
      {
        "schema_version" => 1,
        "pack" => {
          "pack_id" => @pack_id,
          "release_selector" => @release_selector,
          "snapshot_fingerprint" => snapshot_fingerprint,
          "candidate" => nil,
          "candidate_commit" => nil,
          "policy_commit" => nil,
          "tracker_mode" => nil,
          "resolved_packages" => []
        },
        "preflight" => {
          "status" => "pending",
          "waiver" => nil,
          "release_ci" => { "status" => "pending", "evidence" => nil },
          "artifacts" => { "status" => "pending", "evidence" => nil },
          "generator_matrix" => { "status" => "pending", "evidence" => nil },
          "capabilities" => {
            "status" => "pending",
            "permissions" => "pending",
            "git_auth" => "pending",
            "github_auth" => "pending",
            "registry_network" => "pending",
            "toolchains" => "pending",
            "host_capacity" => "pending",
            "coordination" => "pending",
            "restart_handoff" => nil
          }
        },
        "inventory" => inventory.map do |target|
          target.slice("id", "tier", "work_mode").merge(
            "work_state" => "not_started",
            "result" => "pending",
            "waiver" => nil,
            "blocker_id" => nil,
            "package_locks" => [],
            "checks" => %w[install build test local_smoke hosted_ci review].to_h do |check|
              [check, { "status" => "pending", "evidence" => nil, "waiver" => nil, "blocker_id" => nil }]
            end,
            "review_app" => { "state" => "unknown", "evidence" => nil, "deployed_smoke" => "pending" },
            "baseline" => { "classification" => "pending", "evidence" => nil, "waiver" => nil },
            "bases" => {
              "audit" => nil,
              "reviewed" => nil,
              "current" => nil,
              "reconciliation" => "pending"
            },
            "reachability" => {
              "default_branch" => "pending",
              "default_commit" => nil,
              "default_evidence" => nil,
              "tree_parity" => "pending",
              "tree" => nil,
              "tree_evidence" => nil
            },
            "evidence" => nil
          )
        end,
        "required_paths" => required_paths.map do |path|
          path.slice("id", "evidence_source").merge(
            "status" => "pending",
            "lane" => nil,
            "evidence" => nil,
            "waiver" => nil
          )
        end,
        "blockers" => [],
        "audit" => {
          "status" => "pending",
          "checker" => nil,
          "maker_ids" => [],
          "base_commit" => nil
        },
        "merge" => {
          "authority" => "none",
          "authority_evidence" => nil,
          "freeze_state" => "unknown",
          "status" => "not_started",
          "reviewed_base_commit" => nil,
          "current_base_commit" => nil,
          "base_reconciliation" => "pending"
        },
        "reachability" => {
          "default_branch" => "pending",
          "tree_parity" => "pending"
        },
        "tracker" => {
          "status" => "pending",
          "comment_url" => nil,
          "promotion" => "blocked"
        }
      }
    end

    def schema
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "title" => "React on Rails fleet validation result ledger",
        "type" => "object",
        "additionalProperties" => false,
        "required" => %w[
          schema_version pack preflight inventory required_paths blockers audit merge reachability tracker
        ],
        "properties" => {
          "schema_version" => { "const" => 1 },
          "pack" => object_schema(
            %w[
              pack_id release_selector snapshot_fingerprint candidate candidate_commit policy_commit
              tracker_mode resolved_packages
            ],
            {
              "pack_id" => nonempty_string,
              "release_selector" => nonempty_string,
              "snapshot_fingerprint" => nonempty_string,
              "candidate" => nullable_string,
              "candidate_commit" => nullable_string,
              "policy_commit" => nullable_string,
              "tracker_mode" => {
                "type" => %w[string null],
                "enum" => [nil, "development", "accelerated-rc", "strict-rc", "final-release"]
              },
              "resolved_packages" => { "type" => "array", "items" => package_lock_schema }
            }
          ),
          "preflight" => preflight_schema,
          "inventory" => { "type" => "array", "items" => inventory_item_schema },
          "required_paths" => { "type" => "array", "items" => required_path_schema },
          "blockers" => { "type" => "array", "items" => blocker_schema },
          "audit" => audit_schema,
          "merge" => merge_schema,
          "reachability" => object_schema(
            %w[default_branch tree_parity],
            {
              "default_branch" => status_string,
              "tree_parity" => status_string
            }
          ),
          "tracker" => object_schema(
            %w[status comment_url promotion],
            {
              "status" => { "enum" => %w[pending ready posted blocked unknown] },
              "comment_url" => nullable_string,
              "promotion" => { "enum" => %w[recommend hold blocked] }
            }
          )
        }
      }
    end

    private

    def write_ledger(path)
      if File.exist?(path)
        existing = JSON.parse(File.read(path))
        existing_pack = existing.fetch("pack", {})
        if existing_pack["pack_id"] == @pack_id
          same_snapshot = existing_pack["release_selector"] == @release_selector &&
                          existing_pack["snapshot_fingerprint"] == snapshot_fingerprint
          return if same_snapshot

          raise ManifestError, "existing result ledger belongs to a different release snapshot"
        end
      end

      File.write(path, "#{JSON.pretty_generate(ledger_template)}\n")
    rescue JSON::ParserError => e
      raise ManifestError, "existing result ledger is invalid JSON: #{e.message}"
    end

    def build_inventory
      [CORE_INVENTORY_TARGET] + @manifest.fetch("repos").map do |repo|
        tier = repo.fetch("tier")
        {
          "id" => slug(repo.fetch("name")),
          "name" => repo.fetch("name"),
          "headline" => repo.fetch("headline"),
          "tier" => tier,
          "work_mode" => tier == "soft_track" ? "report_only" : "mutation",
          "packages" => Array(repo["packages"]).map { |package| package.slice("ecosystem", "name") }
        }
      end
    end

    def preflight_schema
      fields = %w[
        status waiver release_ci artifacts generator_matrix capabilities
      ]
      object_schema(
        fields,
        {
          "status" => { "enum" => %w[pending passed waived blocked unknown] },
          "waiver" => waiver_schema,
          "release_ci" => preflight_gate_schema,
          "artifacts" => preflight_gate_schema,
          "generator_matrix" => preflight_gate_schema,
          "capabilities" => object_schema(
            %w[
              status permissions git_auth github_auth registry_network toolchains host_capacity
              coordination restart_handoff
            ],
            {
              "status" => status_string,
              "permissions" => status_string,
              "git_auth" => status_string,
              "github_auth" => status_string,
              "registry_network" => status_string,
              "toolchains" => status_string,
              "host_capacity" => status_string,
              "coordination" => status_string,
              "restart_handoff" => nullable_string
            }
          )
        }
      )
    end

    def inventory_item_schema
      object_schema(
        %w[
          id tier work_mode work_state result waiver blocker_id package_locks checks review_app baseline bases reachability evidence
        ],
        {
          "id" => nonempty_string,
          "tier" => { "enum" => %w[hard_gate soft_track] },
          "work_mode" => { "enum" => %w[mutation report_only] },
          "work_state" => { "enum" => %w[not_started running finished blocked unknown] },
          "result" => { "enum" => %w[pending passed reported blocked waived unknown] },
          "waiver" => waiver_schema,
          "blocker_id" => nullable_string,
          "package_locks" => {
            "type" => "array",
            "items" => object_schema(
              %w[ecosystem name version source],
              {
                "ecosystem" => { "enum" => %w[gem npm] },
                "name" => nonempty_string,
                "version" => nonempty_string,
                "source" => nonempty_string
              }
            )
          },
          "checks" => object_schema(
            %w[install build test local_smoke hosted_ci review],
            %w[install build test local_smoke hosted_ci review].to_h do |check|
              [check, evidence_status_schema]
            end
          ),
          "review_app" => object_schema(
            %w[state evidence deployed_smoke],
            {
              "state" => {
                "enum" => %w[configured_runnable configured_broken not_configured unknown]
              },
              "evidence" => nullable_string,
              "deployed_smoke" => status_string
            }
          ),
          "baseline" => object_schema(
            %w[classification evidence waiver],
            {
              "classification" => {
                "enum" => %w[pending clean baseline_defect candidate_regression waived unknown]
              },
              "evidence" => nullable_string,
              "waiver" => waiver_schema
            }
          ),
          "bases" => object_schema(
            %w[audit reviewed current reconciliation],
            {
              "audit" => nullable_string,
              "reviewed" => nullable_string,
              "current" => nullable_string,
              "reconciliation" => status_string
            }
          ),
          "reachability" => object_schema(
            %w[default_branch default_commit default_evidence tree_parity tree tree_evidence],
            {
              "default_branch" => status_string,
              "default_commit" => nullable_string,
              "default_evidence" => nullable_string,
              "tree_parity" => status_string,
              "tree" => nullable_string,
              "tree_evidence" => nullable_string
            }
          ),
          "evidence" => nullable_string
        }
      )
    end

    def required_path_schema
      object_schema(
        %w[id evidence_source status lane evidence waiver],
        {
          "id" => nonempty_string,
          "evidence_source" => nonempty_string,
          "status" => status_string,
          "lane" => nullable_string,
          "evidence" => nullable_string,
          "waiver" => waiver_schema
        }
      )
    end

    def blocker_schema
      object_schema(
        %w[id status public_summary owner],
        {
          "id" => nonempty_string,
          "status" => { "enum" => %w[open pending blocked unknown resolved waived deferred] },
          "public_summary" => nonempty_string,
          "owner" => {
            "type" => %w[object null],
            "additionalProperties" => false,
            "properties" => {
              "issue_url" => nonempty_string,
              "waiver_url" => nonempty_string,
              "public_tracker_reason" => nonempty_string
            }
          }
        }
      )
    end

    def waiver_schema
      {
        "type" => %w[object null],
        "additionalProperties" => false,
        "required" => %w[gate authority evidence_url reason],
        "properties" => {
          "gate" => nonempty_string,
          "authority" => nonempty_string,
          "evidence_url" => nonempty_string,
          "reason" => nonempty_string
        }
      }
    end

    def audit_schema
      object_schema(
        %w[status checker maker_ids base_commit],
        {
          "status" => status_string,
          "checker" => nullable_string,
          "maker_ids" => { "type" => "array", "items" => nonempty_string },
          "base_commit" => nullable_string
        }
      )
    end

    def merge_schema
      object_schema(
        %w[
          authority authority_evidence freeze_state status reviewed_base_commit current_base_commit
          base_reconciliation
        ],
        {
          "authority" => { "enum" => %w[none ask auto_merge_when_gates_pass] },
          "authority_evidence" => nullable_string,
          "freeze_state" => { "enum" => %w[clear frozen conflict unknown] },
          "status" => { "enum" => %w[not_started authorized merged blocked unknown] },
          "reviewed_base_commit" => nullable_string,
          "current_base_commit" => nullable_string,
          "base_reconciliation" => status_string
        }
      )
    end

    def object_schema(required, properties)
      {
        "type" => "object",
        "additionalProperties" => false,
        "required" => required,
        "properties" => properties
      }
    end

    def evidence_status_schema
      object_schema(
        %w[status evidence waiver blocker_id],
        {
          "status" => status_string,
          "evidence" => nullable_string,
          "waiver" => waiver_schema,
          "blocker_id" => nullable_string
        }
      )
    end

    def preflight_gate_schema
      object_schema(
        %w[status evidence],
        {
          "status" => status_string,
          "evidence" => nullable_string
        }
      )
    end

    def nonempty_string
      { "type" => "string", "minLength" => 1 }
    end

    def package_lock_schema
      object_schema(
        %w[ecosystem name version source],
        {
          "ecosystem" => { "enum" => %w[gem npm] },
          "name" => nonempty_string,
          "version" => nonempty_string,
          "source" => nonempty_string
        }
      )
    end

    def nullable_string
      { "type" => %w[string null] }
    end

    def status_string
      { "enum" => %w[pending passed reported blocked waived unknown] }
    end

    def render_lifecycle
      coverage = required_paths.map do |path|
        "| `#{path.fetch('id')}` | #{path.fetch('evidence_source')} | required |"
      end
      <<~MARKDOWN
        # Fleet validation lifecycle

        Pack ID: #{@pack_id}
        Release selector: #{@release_selector}

        This pack covers #{inventory.count { |item| item['tier'] == 'hard_gate' }} hard gates and
        #{inventory.count { |item| item['tier'] == 'soft_track' }} report-only soft tracks.

        1. Phase 0 — snapshot: resolve candidate, exact release commit, policy/default commit, tracker mode, and target defaults once.
        2. Phase 1 — capability preflight: attest machines/sessions and probe target defaults, commands, locks, baseline, and review-app capability.
        3. Phase 2 — release-wide barrier: prove exact-commit CI, artifacts, and the published generator matrix before app mutation.
        4. Phase 3 — fleet execution: run claimed hard gates and inspect every report-only soft track.
        5. Phase 4 — independent audit: reserve a checker that made none of the changes and audit combined evidence.
        6. Phase 5 — authorized merge: re-read tracker mode/freeze and merge only within explicit authority.
        7. Phase 6 — reachability and tree parity: fetch each new default and prove the audited patch landed.
        8. Phase 7 — tracker closeout: validate the ledger and render the append-only disposition matrix.

        `APP_WORK_ALLOWED` is the barrier between phases 2 and 3. Missing, stale, pending, conflicting,
        or `UNKNOWN` evidence never advances the lifecycle.

        ## Required release-path coverage

        | Path | Evidence source | Contract |
        | --- | --- | --- |
        #{coverage.join("\n")}
      MARKDOWN
    end

    def render_preflight
      <<~MARKDOWN
        # Release-wide preflight

        No app mutation coordinator may emit or consume `APP_WORK_ALLOWED` until all release-wide
        gates are terminal:

        - release commit CI is green for the exact candidate commit;
        - registry and tarball artifacts are coherent with that commit; and
        - the published standard / Pro / Pro+RSC generator matrix is green.

        Each gate records both a terminal status and public-safe replayable evidence. A bare `passed`
        status never opens the barrier. Published-artifact defects are non-waivable and must be republished.
        An explicit public-safe waiver may replace a failed gate only when the release policy allows
        it and the ledger records the authority and evidence URL. Missing, pending, conflicting, stale,
        or `UNKNOWN` evidence does not open the barrier.

        Before worker launch, record a machine/session capability attestation covering
        nonblocking permissions, Git and GitHub authentication, registry/network access, required toolchains,
        host capacity, coordination availability, and a restart-safe handoff. Probe each target's fresh
        default branch, repo instructions, package manager/lock, commands, smoke metadata, and review-app
        capability. Classify review apps as
        configured/runnable, configured/broken, not configured, or `UNKNOWN`;
        never wait for an invented review app.
      MARKDOWN
    end

    def render_report_only
      rows = inventory.select { |target| target["tier"] == "soft_track" }.map do |target|
        <<~ROW.chomp
          - `#{target.fetch('id')}` — Report only; do not mutate.
            Inspect the fresh default, current package locks, standing CI/smoke metadata, and archived or deferred disposition.
            Record `reported`, `blocked`, `waived`, or `unknown` plus public-safe evidence in the shared ledger.
        ROW
      end

      <<~MARKDOWN
        # Report-only soft tracks

        Run after the release-wide preflight barrier opens. These tracks complete the release inventory
        but never become candidate bump/merge lanes unless a maintainer separately changes their tier.

        #{rows.join("\n")}
      MARKDOWN
    end

    def render_closeout
      <<~MARKDOWN
        # Independent closeout

        Reserve an independent checker whose identity is absent from every maker ID in the result
        ledger. The checker audits every hard-gate diff, all report-only dispositions, required-path
        coverage, baseline classifications, exact-head CI/review evidence, and blocker ownership.

        Immediately before any merge or tracker write, re-read tracker mode and freeze state. Merge only
        with explicit merge authority and no phase/freeze conflict. Reconcile default-base movement,
        refresh affected checks, and record the audited base in the ledger.

        For each authorized lane, merge through the repository's normal reviewed path, fetch the new
        default, then prove default-branch reachability and tree parity against the audited result.
        A squash merge need not retain the maker head commit, but its resulting tree must contain the
        audited patch.

        Validate the final ledger, regenerate the append-only tracker matrix from that exact file, and
        post it without hand-copying worker prose. End with exact `PASS`, `PARTIAL`, or `BLOCKED`
        semantics. A promotion recommendation is allowed only when every required release path is green
        or explicitly waived and no `UNKNOWN` remains.
      MARKDOWN
    end

    def build_required_paths
      lifecycle = @manifest.fetch("lifecycle", {})
      paths = lifecycle.fetch("required_paths", [])
      unless paths.is_a?(Array) && paths.all? { |path| path.is_a?(Hash) && path["id"].to_s != "" }
        raise ManifestError, "lifecycle.required_paths must contain mappings with IDs"
      end

      paths.map(&:dup)
    end

    def slug(value)
      value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end

    def snapshot_fingerprint
      @snapshot_fingerprint ||= Digest::SHA256.hexdigest(
        JSON.generate(
          "release_selector" => @release_selector,
          "manifest" => @manifest
        )
      )
    end
  end

  class LedgerValidator
    def initialize(ledger, inventory:, required_paths:, expected_candidate: nil, closeout: false)
      @ledger = ledger
      @inventory = inventory
      @required_paths = required_paths
      @expected_candidate = expected_candidate
      @closeout = closeout
    end

    def errors
      result = []
      result << "schema_version must be 1" unless @ledger["schema_version"] == 1
      result << candidate_error if candidate_error
      result.concat(capability_errors)
      result.concat(inventory_errors)
      result.concat(private_field_errors)
      result << "app work started before APP_WORK_ALLOWED" if app_work_started? && !app_work_allowed?
      result << review_app_error if review_app_error
      result.concat(required_path_errors) if @closeout
      result.concat(blocker_owner_errors) if @closeout
      result.concat(blocker_reference_errors) if @closeout
      result.concat(preflight_errors) if @closeout
      result.concat(pack_identity_errors) if @closeout
      result << inventory_completion_error if @closeout && inventory_completion_error
      result << work_state_result_error if @closeout && work_state_result_error
      result << package_lock_error if @closeout && package_lock_error
      result << package_version_error if @closeout && package_version_error
      result << check_evidence_error if @closeout && check_evidence_error
      result.concat(waiver_evidence_errors) if @closeout
      result.concat(base_identity_errors) if @closeout && merge_eligible?
      result << base_movement_error if @closeout && merge_eligible? && base_movement_error
      result.concat(independent_audit_errors) if @closeout
      result << "independent audit is not passed" if @closeout && @ledger.dig("audit", "status") != "passed"
      if @closeout && !present?(@ledger.dig("preflight", "capabilities", "restart_handoff"))
        result << "capability restart_handoff is missing"
      end
      result.concat(reachability_errors) if @closeout && merge_eligible?
      result.concat(tracker_errors) if @closeout
      result << merge_authority_error if @closeout && merge_eligible? && merge_authority_error
      result << promotion_error if @closeout && promotion_error
      if @closeout && merge_eligible? && @ledger.dig("merge", "status") == "merged" &&
         !present?(@ledger.dig("merge", "authority_evidence"))
        result << "merged result is missing explicit authority evidence"
      end
      result
    end

    private

    def app_work_started?
      Array(@ledger["inventory"]).any? do |item|
        item["work_mode"] == "mutation" && item["work_state"] != "not_started"
      end
    end

    def candidate_error
      return unless @expected_candidate

      actual = @ledger.fetch("pack", {})["candidate"]
      return if actual == @expected_candidate

      "candidate mismatch: expected #{@expected_candidate}, got #{actual || 'missing'}"
    end

    def capability_errors
      capabilities = @ledger.fetch("preflight", {}).fetch("capabilities", {})
      capabilities.filter_map do |name, value|
        "capability #{name} is UNKNOWN" if value.to_s.casecmp("unknown").zero?
      end
    end

    def inventory_errors
      actual = Array(@ledger["inventory"])
      expected_by_id = @inventory.to_h { |target| [target.fetch("id"), target] }
      actual_ids = actual.filter_map { |item| item["id"] }
      errors = expected_by_id.filter_map do |id, _target|
        "inventory missing target #{id}" unless actual_ids.include?(id)
      end
      actual_ids.tally.each do |id, count|
        errors << "inventory has duplicate target #{id}" if count > 1
      end
      (actual_ids - expected_by_id.keys).uniq.each do |id|
        errors << "inventory has unexpected target #{id}"
      end
      actual.each do |item|
        expected = expected_by_id[item["id"]]
        next unless expected
        next if item["tier"] == expected["tier"] && item["work_mode"] == expected["work_mode"]

        errors << "inventory target #{item['id']} classification does not match manifest"
      end
      errors
    end

    def private_field_errors
      forbidden = %w[
        app_identity credentials deployment_url logs private_details private_repository private_url
        production_sha route secret_name
      ]
      Array(@ledger["blockers"]).flat_map do |blocker|
        (blocker.keys & forbidden).map do |field|
          "blocker #{blocker['id'] || 'missing-id'} contains forbidden private field #{field}"
        end
      end
    end

    def review_app_error
      count = Array(@ledger["inventory"]).count do |item|
        item["work_state"] != "not_started" && item.dig("review_app", "state").to_s.casecmp("unknown").zero?
      end
      return if count.zero?

      "review app capability UNKNOWN for #{count} started target(s)"
    end

    def required_path_errors
      paths = Array(@ledger["required_paths"])
      @required_paths.filter_map do |required|
        path = paths.find { |item| item["id"] == required.fetch("id") }
        next if path_evidenced?(path)

        "required path #{required.fetch('id')} has no passing evidence or waiver"
      end
    end

    def blocker_owner_errors
      Array(@ledger["blockers"]).filter_map do |blocker|
        next if %w[resolved waived deferred].include?(blocker["status"])
        next if durable_owner?(blocker["owner"])

        "blocker #{blocker['id'] || 'missing-id'} has no durable owner"
      end
    end

    def base_movement_error
      merge = @ledger.fetch("merge", {})
      moved = Array(@ledger["inventory"]).any? do |item|
        next false unless item["tier"] == "hard_gate"

        bases = item.fetch("bases", {})
        present?(bases["reviewed"]) && present?(bases["current"]) &&
          bases["reviewed"] != bases["current"] && bases["reconciliation"] != "passed"
      end
      moved ||= present?(merge["reviewed_base_commit"]) && present?(merge["current_base_commit"]) &&
                merge["reviewed_base_commit"] != merge["current_base_commit"] &&
                merge["base_reconciliation"] != "passed"
      return unless moved

      "base moved after audit without passing reconciliation"
    end

    def preflight_errors
      preflight = @ledger.fetch("preflight", {})
      waiver = preflight["status"] == "waived" ? preflight["waiver"] : nil
      errors = %w[release_ci generator_matrix].filter_map do |field|
        next if preflight_gate_passed?(preflight[field]) || valid_waiver?(waiver, field)

        "release-wide preflight #{field} is not passed or explicitly waived"
      end
      unless preflight_gate_passed?(preflight["artifacts"])
        message = if valid_waiver?(waiver, "artifacts")
                    "release-wide preflight artifacts must pass and cannot be waived"
                  else
                    "release-wide preflight artifacts is not passed or explicitly waived"
                  end
        errors << message
      end
      capabilities = preflight.fetch("capabilities", {})
      %w[status permissions git_auth github_auth registry_network toolchains host_capacity coordination].each do |field|
        next if capabilities[field] == "passed" || valid_waiver?(waiver, "capabilities.#{field}")

        errors << "capability #{field} is not passed or explicitly waived"
      end
      errors
    end

    def pack_identity_errors
      pack = @ledger.fetch("pack", {})
      errors = %w[candidate candidate_commit policy_commit tracker_mode].filter_map do |field|
        "pack #{field} is missing" unless present?(pack[field])
      end
      %w[candidate_commit policy_commit].each do |field|
        errors << "pack #{field} is not an exact commit identity" unless commit_identity?(pack[field])
      end
      allowed_modes = %w[development accelerated-rc strict-rc final-release]
      errors << "pack tracker_mode is not allowed" unless allowed_modes.include?(pack["tracker_mode"])
      errors
    end

    def inventory_completion_error
      count = Array(@ledger["inventory"]).count do |item|
        terminal_results = item["tier"] == "hard_gate" ? %w[passed blocked waived] : %w[reported blocked waived]
        baseline = item.dig("baseline", "classification")
        !terminal_results.include?(item["result"]) || %w[pending unknown].include?(baseline) ||
          !%w[finished blocked].include?(item["work_state"]) || !present?(item["evidence"]) ||
          !present?(item.dig("baseline", "evidence"))
      end
      return if count.zero?

      "#{count} inventory target(s) are unknown or nonterminal"
    end

    def work_state_result_error
      count = Array(@ledger["inventory"]).count do |item|
        allowed = if item["tier"] == "hard_gate"
                    { "finished" => %w[passed waived], "blocked" => ["blocked"] }
                  else
                    { "finished" => %w[reported waived], "blocked" => ["blocked"] }
                  end
        !Array(allowed[item["work_state"]]).include?(item["result"])
      end
      return if count.zero?

      "#{count} inventory target(s) have inconsistent work-state/result combinations"
    end

    def package_lock_error
      expected_by_id = @inventory.to_h { |target| [target.fetch("id"), Array(target["packages"])] }
      count = Array(@ledger["inventory"]).count do |item|
        next false unless item["tier"] == "hard_gate"

        locks = item["package_locks"]
        malformed = !locks.is_a?(Array) || locks.empty? || locks.any? do |lock|
          %w[ecosystem name version source].any? { |field| !present?(lock[field]) }
        end
        next true if malformed

        actual = locks.map { |lock| [lock["ecosystem"], lock["name"]] }
        expected = expected_by_id.fetch(item["id"], []).map { |package| [package["ecosystem"], package["name"]] }
        (expected - actual).any?
      end
      return if count.zero?

      "#{count} hard-gate target(s) are missing retained package lock evidence"
    end

    def package_version_error
      resolved = Array(@ledger.dig("pack", "resolved_packages")).to_h do |package|
        [[package["ecosystem"], package["name"]], package["version"]]
      end
      count = Array(@ledger["inventory"]).count do |item|
        next false unless item["tier"] == "hard_gate"

        Array(item["package_locks"]).any? do |lock|
          resolved[[lock["ecosystem"], lock["name"]]] != lock["version"]
        end
      end
      return if count.zero?

      "#{count} hard-gate target(s) retain package versions outside the resolved release snapshot"
    end

    def check_evidence_error
      count = Array(@ledger["inventory"]).count do |item|
        next false unless item["tier"] == "hard_gate"

        checks = item["checks"]
        !checks.is_a?(Hash) || %w[install build test local_smoke hosted_ci review].any? do |name|
          check = checks[name]
          !check.is_a?(Hash) || !%w[passed blocked waived].include?(check["status"]) ||
            !present?(check["evidence"])
        end
      end
      return if count.zero?

      "#{count} hard-gate target(s) have unknown or nonterminal check evidence"
    end

    def independent_audit_errors
      audit = @ledger.fetch("audit", {})
      errors = []
      errors << "independent audit checker is missing" unless present?(audit["checker"])
      errors << "independent audit maker identities are missing" if Array(audit["maker_ids"]).empty?
      if present?(audit["checker"]) && Array(audit["maker_ids"]).include?(audit["checker"])
        errors << "independent audit checker is also a maker"
      end
      errors
    end

    def base_identity_errors
      audit = @ledger.fetch("audit", {})
      merge = @ledger.fetch("merge", {})
      errors = []
      unless commit_identity?(audit["base_commit"])
        errors << "audit base_commit is missing or not an exact commit identity"
      end
      %w[reviewed_base_commit current_base_commit].each do |field|
        errors << "merge #{field} is missing or not an exact commit identity" unless commit_identity?(merge[field])
      end
      if commit_identity?(audit["base_commit"]) && commit_identity?(merge["reviewed_base_commit"]) &&
         audit["base_commit"] != merge["reviewed_base_commit"]
        errors << "audit base_commit does not match merge reviewed_base_commit"
      end
      Array(@ledger["inventory"]).each do |item|
        next unless item["tier"] == "hard_gate"

        bases = item.fetch("bases", {})
        %w[audit reviewed current].each do |field|
          unless commit_identity?(bases[field])
            errors << "target #{item['id']} #{field} base is missing or not an exact commit identity"
          end
        end
        if commit_identity?(bases["audit"]) && commit_identity?(bases["reviewed"]) &&
           bases["audit"] != bases["reviewed"]
          errors << "target #{item['id']} audit base does not match reviewed base"
        end
      end
      errors
    end

    def blocker_reference_errors
      blockers = Array(@ledger["blockers"]).to_h { |blocker| [blocker["id"], blocker] }
      Array(@ledger["inventory"]).flat_map do |item|
        references = []
        if item["result"] == "blocked" || item.dig("baseline", "classification") == "candidate_regression"
          references << ["result", item["blocker_id"]]
        end
        item.fetch("checks", {}).each do |name, check|
          references << ["check #{name}", check["blocker_id"]] if check["status"] == "blocked"
        end
        references.filter_map do |label, blocker_id|
          blocker = blockers[blocker_id]
          next if blocker && durable_owner?(blocker["owner"])

          "target #{item['id']} blocked #{label} has no owned blocker reference"
        end
      end
    end

    def waiver_evidence_errors
      Array(@ledger["inventory"]).flat_map do |item|
        errors = []
        if item["result"] == "waived" && !valid_waiver?(item["waiver"], item["id"])
          errors << "target #{item['id']} waived result is missing structured waiver evidence"
        end
        if item.dig("baseline", "classification") == "waived" &&
           !valid_waiver?(item.dig("baseline", "waiver"), "#{item['id']}:baseline")
          errors << "target #{item['id']} waived baseline is missing structured waiver evidence"
        end
        item.fetch("checks", {}).each do |name, check|
          next unless check["status"] == "waived"
          next if valid_waiver?(check["waiver"], "#{item['id']}:#{name}")

          errors << "target #{item['id']} waived check #{name} is missing structured waiver evidence"
        end
        errors
      end
    end

    def reachability_errors
      reachability = @ledger.fetch("reachability", {})
      errors = %w[default_branch tree_parity].filter_map do |field|
        "reachability #{field} is not passed" unless reachability[field] == "passed"
      end
      Array(@ledger["inventory"]).each do |item|
        next unless item["tier"] == "hard_gate"

        target = item.fetch("reachability", {})
        unless target["default_branch"] == "passed" && commit_identity?(target["default_commit"]) &&
               present?(target["default_evidence"])
          errors << "target #{item['id']} default-branch reachability evidence is incomplete"
        end
        unless target["tree_parity"] == "passed" && commit_identity?(target["tree"]) &&
               present?(target["tree_evidence"])
          errors << "target #{item['id']} tree-parity evidence is incomplete"
        end
      end
      errors
    end

    def tracker_errors
      tracker = @ledger.fetch("tracker", {})
      errors = []
      errors << "tracker closeout status is not ready or posted" unless %w[ready posted].include?(tracker["status"])
      if tracker["status"] == "posted" && !present?(tracker["comment_url"])
        errors << "posted tracker closeout is missing comment_url"
      end
      errors
    end

    def merge_authority_error
      merge = @ledger.fetch("merge", {})
      return "closeout merge status is not merged" unless merge["status"] == "merged"

      authorized = %w[ask auto_merge_when_gates_pass].include?(merge["authority"])
      conflict = merge["freeze_state"] != "clear" || @ledger.dig("pack", "tracker_mode") == "conflict"
      return if authorized && !conflict

      "merge is not allowed while tracker mode or freeze state conflicts"
    end

    def promotion_error
      return unless @ledger.dig("tracker", "promotion") == "recommend"
      return unless release_blocked?

      "promotion cannot be recommended while release blockers remain"
    end

    def merge_eligible?
      !release_blocked?
    end

    def durable_owner?(owner)
      return false unless owner.is_a?(Hash)

      %w[issue_url waiver_url public_tracker_reason].any? { |key| present?(owner[key]) }
    end

    def path_evidenced?(path)
      return false unless path
      return true if path["status"] == "passed" && present?(path["lane"]) && present?(path["evidence"])

      path["status"] == "waived" && valid_waiver?(path["waiver"], path["id"])
    end

    def present?(value)
      !value.nil? && !value.to_s.empty?
    end

    def commit_identity?(value)
      value.to_s.match?(/\A[0-9a-f]{7,40}\z/i)
    end

    def app_work_allowed?
      preflight = @ledger.fetch("preflight", {})
      %w[passed waived].include?(preflight["status"]) && preflight_errors.empty?
    end

    def valid_waiver?(waiver, expected_gate)
      waiver.is_a?(Hash) && waiver["gate"] == expected_gate &&
        %w[authority evidence_url reason].all? { |field| present?(waiver[field]) }
    end

    def preflight_gate_passed?(gate)
      gate.is_a?(Hash) && gate["status"] == "passed" && present?(gate["evidence"])
    end

    def release_blocked?
      hard_gate_blocked = Array(@ledger["inventory"]).any? do |item|
        next false unless item["tier"] == "hard_gate"

        top_level_blocked = !%w[passed waived].include?(item["result"]) || item["work_state"] == "blocked"
        check_blocked = item.fetch("checks", {}).values.any? { |check| check["status"] == "blocked" }
        candidate_regression = item.dig("baseline", "classification") == "candidate_regression"
        top_level_blocked || check_blocked || candidate_regression
      end
      required_path_blocked = @required_paths.any? do |required|
        path = Array(@ledger["required_paths"]).find { |item| item["id"] == required.fetch("id") }
        !path_evidenced?(path)
      end
      active_blocker = Array(@ledger["blockers"]).any? do |blocker|
        !%w[resolved waived deferred].include?(blocker["status"])
      end

      hard_gate_blocked || required_path_blocked || active_blocker
    end
  end

  class SchemaValidator
    def initialize(schema)
      @schema = schema
    end

    def errors(value)
      validate(value, @schema, "$")
    end

    private

    def validate(value, schema, path)
      errors = []
      errors << "#{path} must equal #{schema['const'].inspect}" if schema.key?("const") && value != schema["const"]
      errors << "#{path} is not an allowed value" if schema["enum"] && !schema["enum"].include?(value)
      return errors unless valid_type?(value, schema["type"], path, errors)

      if value.is_a?(Hash)
        errors.concat(validate_object(value, schema, path))
      elsif value.is_a?(Array) && schema["items"]
        value.each_with_index do |item, index|
          errors.concat(validate(item, schema.fetch("items"), "#{path}[#{index}]"))
        end
      elsif value.is_a?(String) && schema["minLength"] && value.length < schema["minLength"]
        errors << "#{path} is shorter than #{schema['minLength']}"
      end
      errors
    end

    def valid_type?(value, declared, path, errors)
      return true unless declared

      allowed = Array(declared)
      return true if allowed.any? { |type| type_matches?(value, type) }

      errors << "#{path} has invalid type"
      false
    end

    def type_matches?(value, type)
      {
        "array" => Array,
        "integer" => Integer,
        "null" => NilClass,
        "object" => Hash,
        "string" => String
      }.fetch(type).then { |klass| value.is_a?(klass) }
    end

    def validate_object(value, schema, path)
      errors = Array(schema["required"]).filter_map do |field|
        "#{path} is missing required field #{field}" unless value.key?(field)
      end
      properties = schema.fetch("properties", {})
      if schema["additionalProperties"] == false
        (value.keys - properties.keys).each do |field|
          errors << "#{path} has unsupported field #{field}"
        end
      end
      value.each do |field, child|
        next unless properties[field]

        errors.concat(validate(child, properties.fetch(field), "#{path}.#{field}"))
      end
      errors
    end
  end

  class TrackerRenderer
    def initialize(ledger)
      @ledger = ledger
    end

    def render
      rows = @ledger.fetch("inventory").map do |target|
        [
          target["id"],
          target["tier"],
          target["result"],
          target.dig("baseline", "classification"),
          target.dig("review_app", "state"),
          target["evidence"]
        ].map { |value| escape(value) }.then { |cells| "| #{cells.join(' | ')} |" }
      end
      required_path_rows = Array(@ledger["required_paths"]).map do |path|
        [path["id"], path["status"], path["lane"], path["evidence"]]
          .map { |value| escape(value) }
          .then { |cells| "| #{cells.join(' | ')} |" }
      end
      blocker_rows = Array(@ledger["blockers"]).map do |blocker|
        owner = blocker.fetch("owner", nil)
        owner_evidence = owner.is_a?(Hash) ? owner.values.compact.join(", ") : nil
        [blocker["id"], blocker["status"], blocker["public_summary"], owner_evidence]
          .map { |value| escape(value) }
          .then { |cells| "| #{cells.join(' | ')} |" }
      end
      blocker_rows << "| None | resolved | No release blockers recorded | n/a |" if blocker_rows.empty?

      <<~MARKDOWN
        <!-- fleet-validation-closeout:#{escape(@ledger.dig('pack', 'pack_id'))} -->
        ## Fleet validation closeout

        Candidate: #{escape(@ledger.dig('pack', 'candidate'))}
        Verdict: #{verdict}

        | Target | Tier | Result | Baseline | Review app | Evidence |
        | --- | --- | --- | --- | --- | --- |
        #{rows.join("\n")}

        ## Required release paths

        | Path | Status | Lane | Evidence |
        | --- | --- | --- | --- |
        #{required_path_rows.join("\n")}

        ## Blocker ownership

        | Blocker | Status | Public summary | Durable owner |
        | --- | --- | --- | --- |
        #{blocker_rows.join("\n")}

        Promotion recommendation: #{escape(@ledger.dig('tracker', 'promotion'))}
      MARKDOWN
    end

    private

    def verdict
      inventory = Array(@ledger["inventory"])
      blockers = Array(@ledger["blockers"])
      paths = Array(@ledger["required_paths"])
      blocked = inventory.any? do |item|
        next false unless item["tier"] == "hard_gate"

        top_level_blocked = !%w[passed waived].include?(item["result"]) || item["work_state"] == "blocked"
        check_blocked = item.fetch("checks", {}).values.any? { |check| check["status"] == "blocked" }
        candidate_regression = item.dig("baseline", "classification") == "candidate_regression"
        top_level_blocked || check_blocked || candidate_regression
      end
      blocked ||= paths.any? { |path| !%w[passed waived].include?(path["status"]) }
      blocked ||= blockers.any? { |blocker| !%w[resolved waived deferred].include?(blocker["status"]) }
      blocked ||= @ledger.dig("tracker", "promotion") == "blocked"
      return "BLOCKED" if blocked

      partial = inventory.any? do |item|
        target_waived = item["result"] == "waived"
        check_waived = item.fetch("checks", {}).values.any? { |check| check["status"] == "waived" }
        baseline_waived = item.dig("baseline", "classification") == "waived"
        target_waived || check_waived || baseline_waived ||
          (item["tier"] == "soft_track" && item["result"] == "blocked")
      end
      partial ||= @ledger.dig("preflight", "status") == "waived"
      partial ||= %w[release_ci artifacts generator_matrix].any? do |gate|
        @ledger.dig("preflight", gate, "status") == "waived"
      end
      partial ||= paths.any? { |path| path["status"] == "waived" }
      partial ||= blockers.any? { |blocker| %w[waived deferred].include?(blocker["status"]) }
      partial ||= @ledger.dig("tracker", "promotion") == "hold"

      partial ? "PARTIAL" : "PASS"
    end

    def escape(value)
      value.to_s.gsub(/\s+/, " ").strip.gsub("|", "\\|").gsub("<!--", "&lt;!--").gsub("-->", "--&gt;")
    end
  end
end
