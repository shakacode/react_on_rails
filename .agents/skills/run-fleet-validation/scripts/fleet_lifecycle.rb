# frozen_string_literal: true

require "json"
require "digest"
require "time"

module FleetValidation
  class ManifestError < StandardError; end

  module BlockerScope
    module_function

    def soft_only_ids(ledger)
      soft_items = Array(ledger["inventory"]).select { |item| item["tier"] == "soft_track" }
      soft_ids = soft_items.flat_map { |item| target_ids(item) }
      gating_ids = [ledger.dig("preflight", "blocker_id")]
      gating_ids.concat(
        Array(ledger["inventory"]).select { |item| item["tier"] == "hard_gate" }
                                  .flat_map { |item| target_ids(item) }
      )
      gating_ids.concat(Array(ledger["required_paths"]).filter_map { |path| path["blocker_id"] })

      (soft_ids - gating_ids.compact).uniq
    end

    def target_ids(item)
      ids = [item["blocker_id"], item.dig("review_app", "blocker_id")]
      ids.concat(item.fetch("checks", {}).values.filter_map { |check| check["blocker_id"] })
      ids.compact.reject { |id| id.to_s.strip.empty? }
    end
  end

  class Lifecycle
    REQUIRED_PATH_IDS = %w[
      standard-generator pro-ssr pro-rsc rspack webpack-rsc-production ssr-rsc-html
      client-navigation-interaction
    ].freeze

    CORE_INVENTORY_TARGET = {
      "id" => "react-on-rails-generator-install-smoke",
      "name" => "react_on_rails generator/install smoke",
      "headline" => "Monorepo generator and install smoke",
      "tier" => "hard_gate",
      "work_mode" => "validation_only",
      "packages" => [
        { "ecosystem" => "gem", "name" => "react_on_rails" },
        { "ecosystem" => "npm", "name" => "react-on-rails" },
        { "ecosystem" => "npm", "name" => "create-react-on-rails-app" },
        { "ecosystem" => "gem", "name" => "react_on_rails_pro" },
        { "ecosystem" => "npm", "name" => "react-on-rails-pro" },
        { "ecosystem" => "npm", "name" => "react-on-rails-pro-node-renderer" },
        { "ecosystem" => "npm", "name" => "react-on-rails-rsc" }
      ]
    }.freeze

    attr_reader :inventory, :required_paths, :snapshot_fingerprint

    def initialize(manifest:, pack_id:, release_selector:)
      @manifest = manifest
      @pack_id = pack_id
      @release_selector = release_selector
      @snapshot_fingerprint = Digest::SHA256.hexdigest(
        JSON.generate("release_selector" => @release_selector, "manifest" => @manifest)
      )
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
          "app_work_allowed" => false,
          "opened_at" => nil,
          "public_marker" => {
            "status" => "pending",
            "pack_id" => nil,
            "candidate" => nil,
            "candidate_commit" => nil,
            "snapshot_fingerprint" => nil,
            "opened_at" => nil,
            "evidence" => nil
          },
          "waiver" => nil,
          "blocker_id" => nil,
          "blocker_evidence" => nil,
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
            "maker_id" => nil,
            "work_state" => "not_started",
            "work_started_at" => nil,
            "result" => "pending",
            "waiver" => nil,
            "blocker_id" => nil,
            "package_locks" => [],
            "checks" => %w[install build test local_smoke hosted_ci review].to_h do |check|
              [
                check,
                {
                  "status" => "pending",
                  "head_commit" => nil,
                  "base_commit" => nil,
                  "evidence" => nil,
                  "waiver" => nil,
                  "blocker_id" => nil
                }
              ]
            end,
            "review_app" => {
              "state" => "unknown",
              "head_commit" => nil,
              "evidence" => nil,
              "deployed_smoke" => "pending",
              "waiver" => nil,
              "blocker_id" => nil
            },
            "baseline" => {
              "classification" => "pending",
              "head_commit" => nil,
              "evidence" => nil,
              "waiver" => nil
            },
            "revisions" => {
              "audit" => nil,
              "reviewed" => nil,
              "current" => nil,
              "reconciliation" => "pending"
            },
            "bases" => {
              "audit" => nil,
              "reviewed" => nil,
              "current" => nil,
              "reconciliation" => "pending"
            },
            "merge" => {
              "status" => target["work_mode"] == "mutation" ? "not_started" : "not_applicable",
              "authority" => "none",
              "authority_evidence" => nil,
              "freeze_state" => "unknown",
              "merge_commit" => nil,
              "evidence" => nil
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
            "waiver" => nil,
            "blocker_id" => nil
          )
        end,
        "blockers" => [],
        "audit" => {
          "status" => "pending",
          "checker" => nil,
          "maker_ids" => [],
          "evidence" => nil
        },
        "merge" => { "status" => "not_started" },
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
              "default_branch" => aggregate_status_schema,
              "tree_parity" => aggregate_status_schema
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

    def validate_existing_ledger(path)
      return unless File.exist?(path)

      existing = JSON.parse(File.read(path))
      existing_pack = existing.fetch("pack", {})
      return unless existing_pack["pack_id"] == @pack_id

      schema_errors = SchemaValidator.new(schema).errors(existing)
      unless schema_errors.empty?
        raise ManifestError, "existing result ledger does not match the current schema: #{schema_errors.join('; ')}"
      end

      same_snapshot = existing_pack["release_selector"] == @release_selector &&
                      existing_pack["snapshot_fingerprint"] == snapshot_fingerprint
      if same_snapshot && resolved_candidate_reusable?(existing)
        return
      elsif same_snapshot
        raise ManifestError,
              "existing result ledger's resolved dynamic candidate cannot be safely reused; " \
              "pin the exact candidate or generate a fresh pack"
      end

      raise ManifestError, "existing result ledger belongs to a different release snapshot"
    rescue JSON::ParserError => e
      raise ManifestError, "existing result ledger is invalid JSON: #{e.message}"
    end

    private

    def write_ledger(path)
      validate_existing_ledger(path)
      if File.exist?(path)
        existing = JSON.parse(File.read(path))
        return if existing.dig("pack", "pack_id") == @pack_id
      end

      File.write(path, "#{JSON.pretty_generate(ledger_template)}\n")
    rescue JSON::ParserError => e
      raise ManifestError, "existing result ledger is invalid JSON: #{e.message}"
    end

    def build_inventory
      defaults = @manifest.fetch("defaults", {})
      [CORE_INVENTORY_TARGET] + @manifest.fetch("repos").map do |repo|
        tier = repo.fetch("tier")
        effective = tier == "hard_gate" ? defaults.merge(repo) : repo
        {
          "id" => slug(repo.fetch("name")),
          "name" => repo.fetch("name"),
          "headline" => repo.fetch("headline"),
          "tier" => tier,
          "work_mode" => tier == "soft_track" ? "report_only" : "mutation",
          "packages" => Array(effective["packages"]).map { |package| package.slice("ecosystem", "name") }
        }
      end
    end

    def preflight_schema
      fields = %w[
        status app_work_allowed opened_at public_marker waiver blocker_id blocker_evidence release_ci
        artifacts generator_matrix capabilities
      ]
      object_schema(
        fields,
        {
          "status" => { "enum" => %w[pending passed waived blocked unknown] },
          "app_work_allowed" => { "type" => "boolean" },
          "opened_at" => nullable_string,
          "public_marker" => public_marker_schema,
          "waiver" => waiver_schema,
          "blocker_id" => nullable_string,
          "blocker_evidence" => nullable_string,
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
          id tier work_mode maker_id work_state work_started_at result waiver blocker_id package_locks checks
          review_app baseline revisions bases merge reachability evidence
        ],
        {
          "id" => nonempty_string,
          "tier" => { "enum" => %w[hard_gate soft_track] },
          "work_mode" => { "enum" => %w[mutation validation_only report_only] },
          "maker_id" => nullable_string,
          "work_state" => { "enum" => %w[not_started running finished blocked unknown] },
          "work_started_at" => nullable_string,
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
            %w[state head_commit evidence deployed_smoke waiver blocker_id],
            {
              "state" => {
                "enum" => %w[configured_runnable configured_broken not_configured unknown]
              },
              "head_commit" => nullable_string,
              "evidence" => nullable_string,
              "deployed_smoke" => status_string,
              "waiver" => waiver_schema,
              "blocker_id" => nullable_string
            }
          ),
          "baseline" => object_schema(
            %w[classification head_commit evidence waiver],
            {
              "classification" => {
                "enum" => %w[pending clean baseline_defect candidate_regression waived unknown]
              },
              "head_commit" => nullable_string,
              "evidence" => nullable_string,
              "waiver" => waiver_schema
            }
          ),
          "revisions" => revision_schema,
          "bases" => object_schema(
            %w[audit reviewed current reconciliation],
            {
              "audit" => nullable_string,
              "reviewed" => nullable_string,
              "current" => nullable_string,
              "reconciliation" => status_string
            }
          ),
          "merge" => target_merge_schema,
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

    def public_marker_schema
      object_schema(
        %w[status pack_id candidate candidate_commit snapshot_fingerprint opened_at evidence],
        {
          "status" => { "enum" => %w[pending unique absent duplicate mismatched unknown] },
          "pack_id" => nullable_string,
          "candidate" => nullable_string,
          "candidate_commit" => nullable_string,
          "snapshot_fingerprint" => nullable_string,
          "opened_at" => nullable_string,
          "evidence" => nullable_string
        }
      )
    end

    def required_path_schema
      object_schema(
        %w[id evidence_source status lane evidence waiver blocker_id],
        {
          "id" => nonempty_string,
          "evidence_source" => nonempty_string,
          "status" => status_string,
          "lane" => nullable_string,
          "evidence" => nullable_string,
          "waiver" => waiver_schema,
          "blocker_id" => nullable_string
        }
      )
    end

    def blocker_schema
      object_schema(
        %w[id status public_summary owner disposition],
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
          },
          "disposition" => waiver_schema
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
        %w[status checker maker_ids evidence],
        {
          "status" => status_string,
          "checker" => nullable_string,
          "maker_ids" => { "type" => "array", "items" => nonempty_string },
          "evidence" => nullable_string
        }
      )
    end

    def merge_schema
      object_schema(
        %w[status],
        { "status" => { "enum" => %w[not_started merged partial blocked unknown] } }
      )
    end

    def revision_schema
      object_schema(
        %w[audit reviewed current reconciliation],
        {
          "audit" => nullable_string,
          "reviewed" => nullable_string,
          "current" => nullable_string,
          "reconciliation" => status_string
        }
      )
    end

    def target_merge_schema
      object_schema(
        %w[status authority authority_evidence freeze_state merge_commit evidence],
        {
          "status" => { "enum" => %w[not_applicable not_started authorized merged blocked unknown] },
          "authority" => { "enum" => %w[none ask auto_merge_when_gates_pass] },
          "authority_evidence" => nullable_string,
          "freeze_state" => { "enum" => %w[clear frozen conflict unknown] },
          "merge_commit" => nullable_string,
          "evidence" => nullable_string
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
        %w[status head_commit base_commit evidence waiver blocker_id],
        {
          "status" => status_string,
          "head_commit" => nullable_string,
          "base_commit" => nullable_string,
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

    def aggregate_status_schema
      { "enum" => %w[pending passed partial blocked unknown] }
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
        After validating those gates and capabilities, record `preflight.opened_at` and set
        `preflight.app_work_allowed` to `true`; that schema-validated state is the ledger's explicit
        `APP_WORK_ALLOWED` marker. Every mutable target records `work_started_at`, which must be later
        than the barrier time. The validation-only monorepo generator gate may run before this marker.
        Before any remote maker starts, publish a public-safe tracker comment marked
        `<!-- fleet-validation-preflight:#{@pack_id} -->`. It must bind `APP_WORK_ALLOWED` to the exact
        candidate tag and commit, snapshot fingerprint `#{snapshot_fingerprint}`, `preflight.opened_at`,
        and terminal status plus replayable evidence for release CI, artifacts, and generator matrix.
        Remote coordinators cross-check that unique marker against the published pack snapshot; an
        absent, duplicate, stale, malformed, or mismatched marker leaves the barrier `UNKNOWN`.
        Record that cross-check in `preflight.public_marker` with `status: unique`, the exact
        pack/candidate/commit/fingerprint/opened-at fields, and replayable public-safe evidence.
        If an owned release-wide blocker makes opening the barrier impossible, close the pack with
        `preflight.status: blocked`, a durable `preflight.blocker_id`, public-safe
        `preflight.blocker_evidence`, and `APP_WORK_ALLOWED` still false. In that terminal path every
        app target remains untouched, although it may retain read-only package-lock probe evidence.
        The independent audit records no maker IDs, and aggregate merge/reachability plus tracker
        promotion remain blocked.

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
            Retain the inspected package versions/sources and exact-head check evidence; these
            observed versions need not equal the release snapshot. Record `reported`, `blocked`, or
            `waived` plus public-safe evidence in the shared ledger; `pending` or `unknown` cannot
            close the pack.
        ROW
      end

      <<~MARKDOWN
        # Report-only soft tracks

        Run after the release-wide preflight barrier opens. These tracks complete the release inventory
        but never become candidate bump/merge lanes unless a maintainer separately changes their tier.
        An owned blocker referenced only by these soft tracks produces `PARTIAL` follow-up state but
        does not block promotion. A preflight, hard-gate, or required-path reference makes that blocker
        release-gating.

        #{rows.join("\n")}
      MARKDOWN
    end

    def render_closeout
      <<~MARKDOWN
        # Independent closeout

        Reserve an independent checker whose identity is absent from every maker ID in the result
        ledger. The checker audits every hard-gate diff, all report-only dispositions, required-path
        coverage, baseline classifications, exact-head CI/review evidence, and blocker ownership.
        Every mutable target records its maker identity; `audit.maker_ids` must exactly cover those
        identities before independence can pass. The audit records replayable public-safe evidence,
        and every check head must match the target's exact audited, reviewed, and current revision.

        Immediately before each merge or tracker write, re-read tracker mode and freeze state. Record
        authority, freeze state, merge commit, and evidence on that mutable target. Merge only with
        explicit merge authority and no phase/freeze conflict. Reconcile default-base movement, refresh
        affected checks, and record the audited base in the ledger.

        For each authorized lane, merge through the repository's normal reviewed path, fetch the new
        default, then prove default-branch reachability and tree parity against the audited result.
        A squash merge need not retain the maker head commit, but its resulting tree must contain the
        audited patch. The validation-only generator/install gate creates no branch and is therefore
        excluded from per-target merge-base, reachability, and tree-parity evidence, but its exact
        audited revision must equal the pack's candidate commit.

        Validate the final ledger, regenerate the append-only tracker matrix from that exact file, and
        post it without hand-copying worker prose. End with exact `PASS`, `PARTIAL`, or `BLOCKED`
        semantics. A promotion recommendation is allowed only when every required release path is green
        or explicitly waived and no `UNKNOWN` remains. A failed required path closes as `BLOCKED` only
        when it records its lane, failure evidence, and an owned `blocker_id`. Waived or deferred
        blockers retain a durable owner and require structured gate, authority, evidence URL, and
        reason fields. Candidate-snapshot package matching applies to candidate-managed packages on
        hard gates, including the separately resolved RSC package; report-only and independently
        versioned dependency locks retain the versions observed in their target. The resolved release
        snapshot uses the canonical `registry` source; local workspace or path overrides cannot prove
        published-artifact readiness. Blocked outcomes reference active owned blockers, and tracker
        promotion cannot claim `BLOCKED` when no release blocker remains. The aggregate
        merge/reachability state is derived from the per-target rows. If
        any lane has already merged, its base, authority/freeze, merge-commit, reachability, and
        tree-parity proofs remain required even when another lane blocks overall promotion. An
        unmerged blocked lane retains pristine pending reachability with no stale proof fields, while
        a non-mutation lane records an evidenced, freeze-clear `not_applicable` merge disposition.
        Supply the expected pack ID, generated release selector, candidate tag, and candidate source
        commit from the independent launch record when validating; never derive the expected snapshot
        identity from the ledger itself.
      MARKDOWN
    end

    def build_required_paths
      lifecycle = @manifest["lifecycle"]
      paths = lifecycle["required_paths"] if lifecycle.is_a?(Hash)
      unless paths.is_a?(Array) && !paths.empty?
        raise ManifestError, "lifecycle.required_paths must be a nonempty array"
      end

      unless paths.all? do |path|
        path.is_a?(Hash) && %w[id evidence_source].all? do |field|
          path[field].is_a?(String) && !path[field].strip.empty?
        end
      end
        raise ManifestError,
              "lifecycle.required_paths must contain mappings with string IDs and evidence sources"
      end

      duplicates = paths.map { |path| path.fetch("id") }.tally.select { |_id, count| count > 1 }.keys
      unless duplicates.empty?
        raise ManifestError, "lifecycle.required_paths IDs must be unique: #{duplicates.join(', ')}"
      end

      missing = REQUIRED_PATH_IDS - paths.map { |path| path.fetch("id") }
      unless missing.empty?
        raise ManifestError, "lifecycle.required_paths is missing required IDs: #{missing.join(', ')}"
      end

      paths.map(&:dup)
    end

    def slug(value)
      value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end

    def resolved_candidate_reusable?(ledger)
      candidate = ledger.dig("pack", "candidate")
      return !ledger.dig("preflight", "app_work_allowed") if candidate.nil?

      candidate == @release_selector
    end
  end

  class LedgerValidator
    PRODUCT_PACKAGES = {
      "gem" => %w[react_on_rails react_on_rails_pro],
      "npm" => %w[
        react-on-rails create-react-on-rails-app react-on-rails-pro react-on-rails-pro-node-renderer
      ]
    }.freeze

    def initialize(
      ledger,
      inventory:,
      required_paths:,
      expected_candidate: nil,
      expected_candidate_commit: nil,
      expected_pack_id: nil,
      expected_release_selector: nil,
      expected_snapshot_fingerprint: nil,
      closeout: false
    )
      @ledger = ledger
      @inventory = inventory
      @required_paths = required_paths
      @expected_candidate = expected_candidate
      @expected_candidate_commit = expected_candidate_commit
      @expected_pack_id = expected_pack_id
      @expected_release_selector = expected_release_selector
      @expected_snapshot_fingerprint = expected_snapshot_fingerprint
      @closeout = closeout
    end

    def errors
      result = []
      result << "schema_version must be 1" unless @ledger["schema_version"] == 1
      result << candidate_error if candidate_error
      result.concat(capability_errors)
      result.concat(inventory_errors)
      result.concat(private_field_errors)
      result.concat(disposition_state_errors)
      result.concat(timestamp_errors)
      marker_error = public_preflight_marker_error
      result << marker_error if public_preflight_marker_required? && marker_error
      result << "app work started before APP_WORK_ALLOWED" if app_work_started? && !app_work_allowed?
      result.concat(review_app_errors)
      result.concat(barrier_order_errors)
      result << product_candidate_version_error if @closeout && product_candidate_version_error
      if @closeout && preflight_blocked?
        result.concat(blocker_identity_errors)
        result.concat(blocker_owner_errors)
        result.concat(blocker_reference_errors)
        result.concat(preflight_errors)
        result.concat(pack_identity_errors)
        result.concat(blocked_preflight_state_errors)
        result.concat(waiver_evidence_errors)
        result.concat(independent_audit_errors)
        result << "independent audit is not passed" unless @ledger.dig("audit", "status") == "passed"
        result.concat(tracker_errors)
        result << promotion_error if promotion_error
        return result
      end

      result.concat(required_path_errors) if @closeout
      result.concat(blocker_identity_errors) if @closeout
      result.concat(blocker_owner_errors) if @closeout
      result.concat(blocker_reference_errors) if @closeout
      result.concat(preflight_errors) if @closeout
      result.concat(pack_identity_errors) if @closeout
      result << inventory_completion_error if @closeout && inventory_completion_error
      result << work_state_result_error if @closeout && work_state_result_error
      result << package_lock_error if @closeout && package_lock_error
      result << package_version_error if @closeout && package_version_error
      result.concat(check_evidence_errors) if @closeout
      result.concat(revision_evidence_errors) if @closeout
      result.concat(waiver_evidence_errors) if @closeout
      result.concat(base_identity_errors) if @closeout
      result << base_movement_error if @closeout && base_movement_error
      result.concat(independent_audit_errors) if @closeout
      result << "independent audit is not passed" if @closeout && @ledger.dig("audit", "status") != "passed"
      if @closeout && !present?(@ledger.dig("preflight", "capabilities", "restart_handoff"))
        result << "capability restart_handoff is missing"
      end
      result.concat(target_merge_errors) if @closeout
      result.concat(reachability_errors) if @closeout
      result.concat(aggregate_state_errors) if @closeout
      result.concat(tracker_errors) if @closeout
      result << promotion_error if @closeout && promotion_error
      result
    end

    private

    def app_work_started?
      Array(@ledger["inventory"]).any? do |item|
        item["work_mode"] == "mutation" && item["work_state"] != "not_started"
      end
    end

    def preflight_blocked?
      @ledger.dig("preflight", "status") == "blocked"
    end

    def candidate_error
      release_selector = @ledger.dig("pack", "release_selector")
      actual = @ledger.fetch("pack", {})["candidate"]
      if release_selector != "latest RC or beta" && actual != release_selector
        return "candidate mismatch: pinned selector #{release_selector}, got #{actual || 'missing'}"
      end
      return unless @expected_candidate
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

    def disposition_state_errors
      preflight = @ledger.fetch("preflight", {})
      errors = []
      preflight_conflict = case preflight["status"]
                           when "waived"
                             present?(preflight["blocker_id"]) || present?(preflight["blocker_evidence"])
                           when "blocked"
                             !preflight["waiver"].nil?
                           else
                             [
                               !preflight["waiver"].nil?,
                               present?(preflight["blocker_id"]),
                               present?(preflight["blocker_evidence"])
                             ].any?
                           end
      if preflight_conflict
        errors << "#{preflight['status']} preflight retains disposition fields from another state"
      end

      Array(@ledger["inventory"]).each do |item|
        result_blocker_allowed = item["result"] == "blocked" ||
                                 item.dig("baseline", "classification") == "candidate_regression"
        result_conflict = if item["result"] == "waived"
                            present?(item["blocker_id"])
                          elsif item["result"] == "blocked"
                            !item["waiver"].nil?
                          else
                            !item["waiver"].nil? || (present?(item["blocker_id"]) && !result_blocker_allowed)
                          end
        if result_conflict
          errors << "target result #{item['result']} retains disposition fields from another state"
        end

        baseline = item.fetch("baseline", {})
        unless %w[waived baseline_defect].include?(baseline["classification"]) || baseline["waiver"].nil?
          errors << "target baseline #{baseline['classification']} retains a waiver from another state"
        end

        item.fetch("checks", {}).each do |name, check|
          conflict = case check["status"]
                     when "waived"
                       present?(check["blocker_id"])
                     when "blocked"
                       !check["waiver"].nil?
                     else
                       !check["waiver"].nil? || present?(check["blocker_id"])
                     end
          if conflict
            errors << "target check #{name} #{check['status']} retains disposition fields from another state"
          end
        end

        review_app = item.fetch("review_app", {})
        review_conflict = case review_app["deployed_smoke"]
                          when "waived"
                            present?(review_app["blocker_id"])
                          when "blocked"
                            !review_app["waiver"].nil?
                          else
                            !review_app["waiver"].nil? || present?(review_app["blocker_id"])
                          end
        if review_conflict
          errors << "target review-app #{review_app['deployed_smoke']} retains disposition fields from another state"
        end
      end

      Array(@ledger["required_paths"]).each do |path|
        conflict = case path["status"]
                   when "waived"
                     present?(path["blocker_id"])
                   when "blocked"
                     !path["waiver"].nil?
                   else
                     !path["waiver"].nil? || present?(path["blocker_id"])
                   end
        if conflict
          errors << "required path #{path['status']} retains disposition fields from another state"
        end
      end

      Array(@ledger["blockers"]).each do |blocker|
        next if %w[waived deferred].include?(blocker["status"]) || blocker["disposition"].nil?

        errors << "blocker #{blocker['id']} #{blocker['status']} status retains a waiver disposition"
      end
      errors
    end

    def review_app_errors
      errors = []
      count = Array(@ledger["inventory"]).count do |item|
        item["work_state"] != "not_started" && item.dig("review_app", "state").to_s.casecmp("unknown").zero?
      end
      errors << "review app capability UNKNOWN for #{count} started target(s)" unless count.zero?
      return errors unless @closeout
      return errors if preflight_blocked?

      Array(@ledger["inventory"]).each do |item|
        review_app = item.fetch("review_app", {})
        state = review_app["state"]
        evidence = present?(review_app["evidence"])
        passed = review_app["deployed_smoke"] == "passed" && evidence
        blocked = review_app["deployed_smoke"] == "blocked" && evidence
        waived = review_app["deployed_smoke"] == "waived" &&
                 valid_waiver?(review_app["waiver"], "#{item['id']}:review_app")
        terminal = case state
                   when "not_configured"
                     review_app["deployed_smoke"] == "waived" && evidence
                   when "configured_runnable"
                     passed || blocked || waived
                   when "configured_broken"
                     blocked
                   end
        errors << "target #{item['id']} review-app smoke is not terminal" unless terminal
      end
      errors
    end

    def blocked_preflight_state_errors
      errors = Array(@ledger["inventory"]).flat_map do |item|
        if item["work_mode"] == "validation_only" && item["work_state"] != "not_started"
          next validation_only_preflight_evidence_errors(item)
        end

        item_errors = []
        expected_merge_status = item["work_mode"] == "mutation" ? "not_started" : "not_applicable"
        untouched_checks = item.fetch("checks", {}).values.all? do |check|
          check["status"] == "pending" && !present?(check["head_commit"]) && !present?(check["base_commit"]) &&
            !present?(check["evidence"]) && check["waiver"].nil? && !present?(check["blocker_id"])
        end
        untouched = item["work_state"] == "not_started" && !present?(item["work_started_at"]) &&
                    !present?(item["maker_id"]) && item["result"] == "pending" &&
                    untouched_checks && !present?(item["evidence"])
        unless untouched
          item_errors << "blocked preflight target #{item['id']} contains app-work state"
        end
        merge = item.fetch("merge", {})
        pristine_merge = merge["status"] == expected_merge_status && merge["authority"] == "none" &&
                         !present?(merge["authority_evidence"]) && merge["freeze_state"] == "unknown" &&
                         !present?(merge["merge_commit"]) && !present?(merge["evidence"])
        unless pristine_merge
          item_errors << "blocked preflight target #{item['id']} contains nested merge state"
        end
        unless pristine_reachability?(item.fetch("reachability", {}))
          item_errors << "blocked preflight target #{item['id']} contains reachability state"
        end
        item_errors
      end
      errors << "blocked preflight aggregate merge status must be blocked" unless @ledger.dig("merge", "status") == "blocked"
      unless @ledger.dig("tracker", "promotion") == "blocked"
        errors << "blocked preflight tracker promotion must be blocked"
      end
      %w[default_branch tree_parity].each do |field|
        unless @ledger.dig("reachability", field) == "blocked"
          errors << "blocked preflight aggregate reachability #{field} must be blocked"
        end
      end
      errors
    end

    def validation_only_preflight_evidence_errors(item)
      errors = []
      allowed = { "finished" => %w[passed waived], "blocked" => ["blocked"] }
      unless Array(allowed[item["work_state"]]).include?(item["result"]) && present?(item["evidence"])
        errors << "blocked preflight validation-only target #{item['id']} is not terminal"
      end
      errors << "blocked preflight validation-only target #{item['id']} has a maker" if present?(item["maker_id"])

      revisions = item.fetch("revisions", {})
      current_head = revisions["current"]
      unless %w[audit reviewed current].all? { |field| commit_identity?(revisions[field]) } &&
             revisions["audit"] == revisions["reviewed"] && revisions["reviewed"] == current_head &&
             revisions["reconciliation"] == "passed"
        errors << "blocked preflight validation-only target #{item['id']} has incomplete revision evidence"
      end
      candidate_revision_error = validation_only_candidate_revision_error(item, current_head)
      errors << candidate_revision_error if candidate_revision_error

      expected = @inventory.find { |target| target["id"] == item["id"] }
      expected_packages = Array(expected&.fetch("packages", [])).map do |package|
        [package["ecosystem"], package["name"]]
      end
      locks = Array(item["package_locks"])
      actual_packages = locks.map { |lock| [lock["ecosystem"], lock["name"]] }
      resolved = Array(@ledger.dig("pack", "resolved_packages")).to_h do |package|
        [[package["ecosystem"], package["name"]], [package["version"], package["source"]]]
      end
      invalid_locks = locks.any? do |lock|
        !%w[ecosystem name version source].all? { |field| present?(lock[field]) } ||
          resolved[[lock["ecosystem"], lock["name"]]] != [lock["version"], lock["source"]]
      end
      if (expected_packages - actual_packages).any? || actual_packages.tally.any? { |_identity, count| count > 1 } ||
         invalid_locks
        errors << "blocked preflight validation-only target #{item['id']} has incomplete package evidence"
      end

      checks_terminal = item.fetch("checks", {}).values.all? do |check|
        %w[passed blocked waived].include?(check["status"]) && present?(check["evidence"]) &&
          commit_identity?(check["head_commit"]) && check["head_commit"] == current_head
      end
      unless checks_terminal
        errors << "blocked preflight validation-only target #{item['id']} has incomplete check evidence"
      end

      baseline = item.fetch("baseline", {})
      baseline_terminal = !%w[pending unknown].include?(baseline["classification"]) &&
                          baseline["head_commit"] == current_head && present?(baseline["evidence"])
      unless baseline_terminal
        errors << "blocked preflight validation-only target #{item['id']} has incomplete baseline evidence"
      end
      review_app = item.fetch("review_app", {})
      review_terminal = review_app["head_commit"] == current_head && present?(review_app["evidence"]) &&
                        validation_only_review_terminal?(item, review_app)
      unless review_terminal
        errors << "blocked preflight validation-only target #{item['id']} has incomplete review-app evidence"
      end

      merge = item.fetch("merge", {})
      unless merge["status"] == "not_applicable" && merge["authority"] == "none" &&
             !present?(merge["authority_evidence"]) && !present?(merge["merge_commit"])
        errors << "blocked preflight validation-only target #{item['id']} contains mutation merge state"
      end
      unless pristine_reachability?(item.fetch("reachability", {}))
        errors << "blocked preflight validation-only target #{item['id']} contains reachability state"
      end
      errors
    end

    def validation_only_review_terminal?(item, review_app)
      case review_app["state"]
      when "not_configured"
        review_app["deployed_smoke"] == "waived"
      when "configured_runnable"
        review_app["deployed_smoke"] == "passed" ||
          (review_app["deployed_smoke"] == "blocked") ||
          (review_app["deployed_smoke"] == "waived" &&
            valid_waiver?(review_app["waiver"], "#{item['id']}:review_app"))
      when "configured_broken"
        review_app["deployed_smoke"] == "blocked"
      else
        false
      end
    end

    def barrier_order_errors
      opened_at = timestamp(@ledger.dig("preflight", "opened_at"))
      Array(@ledger["inventory"]).filter_map do |item|
        next if item["work_mode"] == "validation_only" || item["work_state"] == "not_started"

        started_at = timestamp(item["work_started_at"])
        if !opened_at || !started_at
          "target #{item['id']} is missing replayable barrier/work-start ordering evidence"
        elsif started_at <= opened_at
          "target #{item['id']} started before the preflight barrier opened"
        end
      end
    end

    def required_path_errors
      paths = Array(@ledger["required_paths"])
      errors = []
      paths.filter_map { |path| path["id"] }.tally.each do |id, count|
        errors << "required paths contain duplicate ID #{id}" if count > 1
      end
      expected_ids = @required_paths.map { |path| path.fetch("id") }
      (paths.filter_map { |path| path["id"] } - expected_ids).uniq.each do |id|
        errors << "required paths contain unexpected ID #{id}"
      end
      errors + @required_paths.flat_map do |required|
        path = paths.find { |item| item["id"] == required.fetch("id") }
        errors = []
        if path && path["evidence_source"] != required["evidence_source"]
          errors << "required path #{required.fetch('id')} evidence_source does not match manifest"
        end
        unless path_terminally_evidenced?(path)
          errors << "required path #{required.fetch('id')} has no passing, blocked, or waived evidence"
        end

        errors
      end
    end

    def blocker_owner_errors
      Array(@ledger["blockers"]).flat_map do |blocker|
        status = blocker["status"]
        errors = []
        if status == "unknown"
          errors << "blocker #{blocker['id'] || 'missing-id'} remains UNKNOWN at closeout"
        end
        if %w[waived deferred].include?(status) &&
           !valid_waiver?(blocker["disposition"], blocker["id"])
          errors << "blocker #{blocker['id'] || 'missing-id'} " \
                    "is missing structured #{status} disposition evidence"
        end
        if status != "resolved" && !durable_owner?(blocker["owner"])
          errors << "blocker #{blocker['id'] || 'missing-id'} has no durable owner"
        end

        errors
      end
    end

    def blocker_identity_errors
      ids = Array(@ledger["blockers"]).map { |blocker| blocker["id"] }
      duplicates = ids.tally.select { |_id, count| count > 1 }.keys
      return [] if duplicates.empty?

      ["blocker IDs must be unique: #{duplicates.join(', ')}"]
    end

    def base_movement_error
      moved = Array(@ledger["inventory"]).any? do |item|
        next false unless item["work_mode"] == "mutation"

        bases = item.fetch("bases", {})
        present?(bases["reviewed"]) && present?(bases["current"]) &&
          bases["reviewed"] != bases["current"] && bases["reconciliation"] != "passed"
      end
      return unless moved

      "base moved after audit without passing reconciliation"
    end

    def timestamp_errors
      errors = []
      opened_at = @ledger.dig("preflight", "opened_at")
      if present?(opened_at) && !timestamp(opened_at)
        errors << "preflight opened_at must be an ISO8601 timestamp with an explicit offset"
      end
      Array(@ledger["inventory"]).each do |item|
        work_started_at = item["work_started_at"]
        next unless present?(work_started_at) && !timestamp(work_started_at)

        errors << "target #{item['id']} work_started_at must be an ISO8601 timestamp with an explicit offset"
      end
      errors
    end

    def preflight_errors
      preflight = @ledger.fetch("preflight", {})
      if preflight["status"] == "blocked"
        errors = []
        errors << "blocked preflight must keep APP_WORK_ALLOWED closed" unless preflight["app_work_allowed"] == false
        errors << "blocked preflight must not record an opened barrier" if present?(preflight["opened_at"])
        errors << "blocked preflight is missing public-safe blocker evidence" unless present?(preflight["blocker_evidence"])
        blocked_gate = %w[release_ci artifacts generator_matrix].any? do |field|
          preflight.dig(field, "status") == "blocked" && present?(preflight.dig(field, "evidence"))
        end
        blocked_capability = preflight.fetch("capabilities", {}).any? do |field, status|
          field != "restart_handoff" && status == "blocked"
        end
        errors << "blocked preflight has no explicitly blocked gate or capability" unless blocked_gate || blocked_capability
        return errors
      end

      waiver = preflight["status"] == "waived" ? preflight["waiver"] : nil
      errors = if preflight["status"] == "waived" && !terminal_preflight_waiver?(preflight, waiver)
                 ["waived preflight has no terminal failed gate with replayable evidence"]
               else
                 []
               end
      errors.concat(%w[release_ci generator_matrix].filter_map do |field|
        next if preflight_gate_passed?(preflight[field]) || valid_preflight_waiver?(waiver, field, preflight[field])

        "release-wide preflight #{field} is not passed or explicitly waived"
      end)
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
        next if capabilities[field] == "passed" ||
                valid_preflight_capability_waiver?(waiver, field, capabilities[field])

        errors << "capability #{field} is not passed or explicitly waived"
      end
      errors << "capability restart_handoff is missing" unless present?(capabilities["restart_handoff"])
      errors
    end

    def pack_identity_errors
      pack = @ledger.fetch("pack", {})
      errors = %w[candidate candidate_commit policy_commit tracker_mode snapshot_fingerprint].filter_map do |field|
        "pack #{field} is missing" unless present?(pack[field])
      end
      %w[candidate_commit policy_commit].each do |field|
        errors << "pack #{field} is not an exact commit identity" unless commit_identity?(pack[field])
      end
      allowed_modes = %w[development accelerated-rc strict-rc final-release]
      errors << "pack tracker_mode is not allowed" unless allowed_modes.include?(pack["tracker_mode"])
      expected_packages = @inventory.select { |target| target["tier"] == "hard_gate" }
                                    .flat_map { |target| Array(target["packages"]) }
                                    .map { |package| [package["ecosystem"], package["name"]] }
                                    .uniq
      resolved_packages = Array(pack["resolved_packages"])
      actual_packages = resolved_packages.map { |package| [package["ecosystem"], package["name"]] }
      if (expected_packages - actual_packages).any? ||
         resolved_packages.any? { |package| !present?(package["version"]) || !present?(package["source"]) }
        errors << "pack resolved package snapshot is incomplete"
      end
      if actual_packages.tally.any? { |_identity, count| count > 1 }
        errors << "pack resolved package snapshot contains duplicate identities"
      end
      if resolved_packages.any? { |package| package["source"] != "registry" }
        errors << "pack resolved package snapshot contains unpublished sources"
      end
      if @expected_snapshot_fingerprint && pack["snapshot_fingerprint"] != @expected_snapshot_fingerprint
        errors << "pack snapshot_fingerprint does not match the current manifest"
      end
      if @expected_pack_id && pack["pack_id"] != @expected_pack_id
        errors << "pack ID mismatch: expected #{@expected_pack_id}, got #{pack['pack_id']}"
      end
      if @expected_release_selector && pack["release_selector"] != @expected_release_selector
        errors << "pack release selector mismatch: expected #{@expected_release_selector}, " \
                  "got #{pack['release_selector']}"
      end
      if @expected_candidate_commit && pack["candidate_commit"] != @expected_candidate_commit
        errors << "pack candidate commit mismatch: expected #{@expected_candidate_commit}, " \
                  "got #{pack['candidate_commit']}"
      end
      errors
    end

    def product_candidate_version_error
      candidate = @ledger.dig("pack", "candidate").to_s
      match = candidate.match(/\Av?(\d+\.\d+\.\d+)(?:\.(rc|beta)\.(\d+))?\z/)
      return "candidate #{candidate} cannot be normalized to product package versions" unless match

      gem_version = candidate.delete_prefix("v")
      npm_version = match[2] ? "#{match[1]}-#{match[2]}.#{match[3]}" : match[1]
      expected = { "gem" => gem_version, "npm" => npm_version }
      mismatched = Array(@ledger.dig("pack", "resolved_packages")).any? do |package|
        names = PRODUCT_PACKAGES.fetch(package["ecosystem"], [])
        names.include?(package["name"]) && package["version"] != expected.fetch(package["ecosystem"])
      end
      return unless mismatched

      "resolved product package versions do not match candidate #{candidate}"
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
      invalid_items = Array(@ledger["inventory"]).select do |item|
        locks = item["package_locks"]
        expected = expected_by_id.fetch(item["id"], []).map { |package| [package["ecosystem"], package["name"]] }
        malformed = !locks.is_a?(Array) || (expected.any? && locks.empty?) || Array(locks).any? do |lock|
          %w[ecosystem name version source].any? { |field| !present?(lock[field]) }
        end
        next true if malformed

        actual = locks.map { |lock| [lock["ecosystem"], lock["name"]] }
        (expected - actual).any? || actual.tally.any? { |_identity, total| total > 1 }
      end
      return if invalid_items.empty?

      hard_gate_count = invalid_items.count { |item| item["tier"] == "hard_gate" }
      if hard_gate_count.positive?
        "#{hard_gate_count} hard-gate target(s) are missing retained package lock evidence"
      else
        "#{invalid_items.length} inventory target(s) are missing retained package lock evidence"
      end
    end

    def package_version_error
      resolved = Array(@ledger.dig("pack", "resolved_packages")).to_h do |package|
        [[package["ecosystem"], package["name"]], [package["version"], package["source"]]]
      end
      invalid_items = Array(@ledger["inventory"]).select do |item|
        next false unless item["tier"] == "hard_gate"

        Array(item["package_locks"]).any? do |lock|
          next false unless candidate_managed_package?(lock["ecosystem"], lock["name"])

          resolved[[lock["ecosystem"], lock["name"]]] != [lock["version"], lock["source"]]
        end
      end
      return if invalid_items.empty?

      "#{invalid_items.length} hard-gate target(s) retain package versions or sources outside the resolved release snapshot"
    end

    def candidate_managed_package?(ecosystem, name)
      PRODUCT_PACKAGES.fetch(ecosystem, []).include?(name) ||
        (ecosystem == "npm" && name == "react-on-rails-rsc")
    end

    def check_evidence_errors
      invalid_head_items = []
      invalid_base_items = []
      Array(@ledger["inventory"]).each do |item|
        checks = item["checks"]
        current_head = item.dig("revisions", "current")
        current_base = item.dig("bases", "current")
        allowed_statuses = item["tier"] == "hard_gate" ? %w[passed blocked waived] : %w[passed reported blocked waived]
        invalid_head = !checks.is_a?(Hash) || %w[install build test local_smoke hosted_ci review].any? do |name|
          check = checks[name]
          !check.is_a?(Hash) || !allowed_statuses.include?(check["status"]) ||
            !present?(check["evidence"]) || !commit_identity?(check["head_commit"]) ||
            check["head_commit"] != current_head
        end
        invalid_base = item["work_mode"] == "mutation" &&
                       (!checks.is_a?(Hash) || %w[install build test local_smoke hosted_ci review].any? do |name|
                         check = checks[name]
                         !check.is_a?(Hash) || !commit_identity?(check["base_commit"]) ||
                           check["base_commit"] != current_base
                       end)
        invalid_head_items << item if invalid_head
        invalid_base_items << item if invalid_base
      end
      hard_gate_count = invalid_head_items.count { |item| item["tier"] == "hard_gate" }
      report_only_count = invalid_head_items.count { |item| item["work_mode"] == "report_only" }
      errors = []
      if hard_gate_count.positive?
        errors << "#{hard_gate_count} hard-gate target(s) check evidence is not bound to its immutable current head"
      end
      if report_only_count.positive?
        errors << "#{report_only_count} report-only target(s) have unknown or stale check evidence"
      end
      invalid_base_items.each do |item|
        errors << "target #{item['id']} check evidence is not bound to its reconciled current base"
      end
      errors
    end

    def revision_evidence_errors
      Array(@ledger["inventory"]).flat_map do |item|
        revisions = item.fetch("revisions", {})
        errors = []
        %w[audit reviewed current].each do |field|
          errors << "target #{item['id']} #{field} revision is missing" unless commit_identity?(revisions[field])
        end
        if commit_identity?(revisions["audit"]) && revisions["audit"] != revisions["reviewed"]
          errors << "target #{item['id']} audit revision does not match reviewed revision"
        end
        if commit_identity?(revisions["current"]) && revisions["current"] != revisions["reviewed"]
          errors << "target #{item['id']} current revision does not match reviewed revision"
        end
        errors << "target #{item['id']} revision reconciliation is not passed" unless revisions["reconciliation"] == "passed"
        candidate_revision_error = validation_only_candidate_revision_error(item, revisions["current"])
        errors << candidate_revision_error if candidate_revision_error

        review_app = item.fetch("review_app", {})
        if !commit_identity?(review_app["head_commit"]) || review_app["head_commit"] != revisions["current"]
          errors << "target #{item['id']} review-app evidence is not bound to its immutable current head"
        end
        baseline = item.fetch("baseline", {})
        expected_baseline_head = if item["work_mode"] == "mutation"
                                   item.dig("bases", "current")
                                 else
                                   revisions["current"]
                                 end
        if !commit_identity?(baseline["head_commit"]) || baseline["head_commit"] != expected_baseline_head
          errors << "target #{item['id']} baseline evidence is not bound to its fresh-default head"
        end
        errors
      end
    end

    def independent_audit_errors
      audit = @ledger.fetch("audit", {})
      errors = []
      audit_maker_ids = Array(audit["maker_ids"])
      raw_mutable_maker_ids = Array(@ledger["inventory"]).filter_map do |item|
        item["maker_id"] if item["work_mode"] == "mutation"
      end
      mutable_count = Array(@ledger["inventory"]).count { |item| item["work_mode"] == "mutation" }
      errors << "independent audit checker is missing" unless present?(audit["checker"])
      errors << "independent audit evidence is missing" unless present?(audit["evidence"])
      if preflight_blocked?
        unless raw_mutable_maker_ids.none? { |maker_id| present?(maker_id) } && audit_maker_ids.empty?
          errors << "blocked preflight audit must not claim maker identities"
        end
      else
        errors << "independent audit maker identities are missing" if audit_maker_ids.empty?
        if audit_maker_ids.length != audit_maker_ids.uniq.length
          errors << "independent audit maker identities must be unique"
        end
        if raw_mutable_maker_ids.any? { |maker_id| !present?(maker_id) } ||
           audit_maker_ids.any? { |maker_id| !present?(maker_id) }
          errors << "independent audit maker identities contain blank values"
        end
        mutable_maker_ids = raw_mutable_maker_ids.select { |maker_id| present?(maker_id) }
        if mutable_maker_ids.length != mutable_count || mutable_maker_ids.uniq.sort != audit_maker_ids.uniq.sort
          errors << "independent audit maker identities do not cover every mutable target"
        end
      end
      if present?(audit["checker"]) && audit_maker_ids.include?(audit["checker"])
        errors << "independent audit checker is also a maker"
      end
      errors
    end

    def base_identity_errors
      errors = []
      Array(@ledger["inventory"]).each do |item|
        next unless item["work_mode"] == "mutation"

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
        unless bases["reconciliation"] == "passed"
          errors << "target #{item['id']} base reconciliation is not passed"
        end
      end
      errors
    end

    def blocker_reference_errors
      blockers = Array(@ledger["blockers"]).to_h { |blocker| [blocker["id"], blocker] }
      preflight_errors = []
      if preflight_blocked?
        blocker = blockers[@ledger.dig("preflight", "blocker_id")]
        if blocker && durable_owner?(blocker["owner"])
          preflight_errors << inactive_blocker_error("blocked preflight", blocker) unless active_blocker?(blocker)
        else
          preflight_errors << "blocked preflight has no owned blocker reference"
        end
      end
      inventory_errors = Array(@ledger["inventory"]).flat_map do |item|
        references = []
        if item["result"] == "blocked" || item.dig("baseline", "classification") == "candidate_regression"
          references << ["result", item["blocker_id"]]
        end
        item.fetch("checks", {}).each do |name, check|
          references << ["check #{name}", check["blocker_id"]] if check["status"] == "blocked"
        end
        review_app = item.fetch("review_app", {})
        if review_app["state"] == "configured_broken" || review_app["deployed_smoke"] == "blocked"
          references << ["review app", review_app["blocker_id"]]
        end
        references.filter_map do |label, blocker_id|
          blocker = blockers[blocker_id]
          if blocker && durable_owner?(blocker["owner"])
            next if active_blocker?(blocker)

            next inactive_blocker_error("target #{item['id']} blocked #{label}", blocker)
          end

          "target #{item['id']} blocked #{label} has no owned blocker reference"
        end
      end
      path_errors = Array(@ledger["required_paths"]).filter_map do |path|
        next unless path["status"] == "blocked"

        blocker = blockers[path["blocker_id"]]
        if blocker && durable_owner?(blocker["owner"])
          next if active_blocker?(blocker)

          next inactive_blocker_error("required path #{path['id']} blocked result", blocker)
        end

        "required path #{path['id']} blocked result has no owned blocker reference"
      end
      preflight_errors + inventory_errors + path_errors
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
        if item.dig("baseline", "classification") == "baseline_defect" &&
           !valid_waiver?(item.dig("baseline", "waiver"), "#{item['id']}:baseline")
          errors << "target #{item['id']} baseline defect is missing structured waiver evidence"
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
      Array(@ledger["inventory"]).flat_map do |item|
        next [] unless item["work_mode"] == "mutation" && item.dig("merge", "status") == "merged"

        target = item.fetch("reachability", {})
        errors = []
        unless target["default_branch"] == "passed" && commit_identity?(target["default_commit"]) &&
               present?(target["default_evidence"])
          errors << "target #{item['id']} default-branch reachability evidence is incomplete"
        end
        unless target["tree_parity"] == "passed" && commit_identity?(target["tree"]) &&
               present?(target["tree_evidence"])
          errors << "target #{item['id']} tree-parity evidence is incomplete"
        end
        errors
      end
    end

    def tracker_errors
      tracker = @ledger.fetch("tracker", {})
      errors = []
      errors << "tracker closeout status is not ready or posted" unless %w[ready posted].include?(tracker["status"])
      if tracker["status"] == "posted" && !present?(tracker["comment_url"])
        errors << "posted tracker closeout is missing comment_url"
      end
      if tracker["promotion"] == "blocked" && !release_blocked?
        errors << "tracker promotion is blocked without a release blocker"
      end
      errors
    end

    def target_merge_errors
      Array(@ledger["inventory"]).flat_map do |item|
        merge = item.fetch("merge", {})
        if item["work_mode"] != "mutation"
          errors = []
          errors << "target #{item['id']} must mark merge not_applicable" unless merge["status"] == "not_applicable"
          if merge["authority"] != "none" || present?(merge["authority_evidence"]) ||
             present?(merge["merge_commit"])
            errors << "target #{item['id']} not-applicable merge retains mutation state"
          end
          unless merge["freeze_state"] == "clear" && present?(merge["evidence"])
            errors << "target #{item['id']} not-applicable merge disposition is incomplete"
          end
          unless pristine_reachability?(item.fetch("reachability", {}))
            errors << "target #{item['id']} non-mutation target retains reachability state"
          end
          next errors
        end

        errors = []
        unless %w[merged blocked].include?(merge["status"])
          errors << "target #{item['id']} merge disposition is not terminal"
        end
        if merge["status"] == "merged"
          authorized = %w[ask auto_merge_when_gates_pass].include?(merge["authority"])
          if target_blocked_gate?(item)
            errors << "target #{item['id']} merged despite its own blocked gate outcome"
          end
          errors << "target #{item['id']} merged without explicit authority" unless authorized
          errors << "target #{item['id']} merged without authority evidence" unless present?(merge["authority_evidence"])
          errors << "target #{item['id']} merged during a freeze or phase conflict" unless merge["freeze_state"] == "clear"
          errors << "target #{item['id']} merge commit is missing" unless commit_identity?(merge["merge_commit"])
          errors << "target #{item['id']} merge evidence is missing" unless present?(merge["evidence"])
        elsif merge["status"] == "blocked"
          errors << "target #{item['id']} blocked merge disposition has no evidence" unless present?(merge["evidence"])
          if merge["authority"] != "none" || present?(merge["authority_evidence"])
            errors << "target #{item['id']} blocked merge retains mutation authority"
          end
          unless merge["freeze_state"] == "clear"
            errors << "target #{item['id']} blocked merge freeze state is unresolved"
          end
          if present?(merge["merge_commit"])
            errors << "target #{item['id']} blocked merge retains a merge commit"
          end
          reachability = item.fetch("reachability", {})
          if reachability["default_branch"] == "passed" || reachability["tree_parity"] == "passed"
            errors << "target #{item['id']} blocked merge retains successful reachability"
          end
          unless pristine_reachability?(reachability)
            errors << "target #{item['id']} blocked merge retains unresolved reachability"
          end
        end
        if !release_blocked? && merge["status"] != "merged"
          errors << "target #{item['id']} merge is incomplete for a promotable release"
        end
        errors
      end
    end

    def target_blocked_gate?(item)
      review_app = item.fetch("review_app", {})
      item["result"] == "blocked" ||
        item.fetch("checks", {}).values.any? { |check| check["status"] == "blocked" } ||
        item.dig("baseline", "classification") == "candidate_regression" ||
        review_app["state"] == "configured_broken" ||
        review_app["deployed_smoke"] == "blocked"
    end

    def aggregate_state_errors
      mutation_items = Array(@ledger["inventory"]).select { |item| item["work_mode"] == "mutation" }
      merged_count = mutation_items.count { |item| item.dig("merge", "status") == "merged" }
      expected_merge = if merged_count == mutation_items.length
                         "merged"
                       elsif merged_count.positive?
                         "partial"
                       else
                         "blocked"
                       end
      expected_reachability = if expected_merge == "merged"
                                "passed"
                              elsif expected_merge == "partial"
                                "partial"
                              else
                                "blocked"
                              end
      errors = []
      unless @ledger.dig("merge", "status") == expected_merge
        errors << "aggregate merge status does not match per-target merge states"
      end
      %w[default_branch tree_parity].each do |field|
        unless @ledger.dig("reachability", field) == expected_reachability
          errors << "aggregate reachability #{field} does not match per-target merge states"
        end
      end
      errors
    end

    def promotion_error
      return unless @ledger.dig("tracker", "promotion") == "recommend"
      return unless release_blocked?

      "promotion cannot be recommended while release blockers remain"
    end

    def durable_owner?(owner)
      return false unless owner.is_a?(Hash)

      %w[issue_url waiver_url public_tracker_reason].any? { |key| present?(owner[key]) }
    end

    def active_blocker?(blocker)
      %w[open pending blocked unknown].include?(blocker["status"])
    end

    def inactive_blocker_error(subject, blocker)
      "#{subject} references inactive blocker #{blocker['id']}"
    end

    def path_terminally_evidenced?(path)
      return false unless path
      return true if path["status"] == "passed" && present?(path["lane"]) && present?(path["evidence"])
      return true if path["status"] == "blocked" && present?(path["lane"]) && present?(path["evidence"])

      path["status"] == "waived" && valid_waiver?(path["waiver"], path["id"])
    end

    def present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end

    def pristine_reachability?(reachability)
      reachability["default_branch"] == "pending" && !present?(reachability["default_commit"]) &&
        !present?(reachability["default_evidence"]) && reachability["tree_parity"] == "pending" &&
        !present?(reachability["tree"]) && !present?(reachability["tree_evidence"])
    end

    def commit_identity?(value)
      value.to_s.match?(/\A[0-9a-f]{40}\z/i)
    end

    def validation_only_candidate_revision_error(item, revision)
      candidate_commit = @ledger.dig("pack", "candidate_commit")
      return unless item["work_mode"] == "validation_only"
      return unless commit_identity?(revision) && commit_identity?(candidate_commit)
      return if revision == candidate_commit

      "validation-only target revision does not match the candidate commit"
    end

    def app_work_allowed?
      preflight = @ledger.fetch("preflight", {})
      preflight["app_work_allowed"] == true &&
        timestamp(preflight["opened_at"]) &&
        %w[passed waived].include?(preflight["status"]) &&
        preflight_errors.empty? && pack_identity_errors.empty? && candidate_error.nil? &&
        public_preflight_marker_error.nil?
    end

    def public_preflight_marker_required?
      app_work_started? || @ledger.dig("preflight", "app_work_allowed") == true ||
        (@closeout && !preflight_blocked?)
    end

    def public_preflight_marker_error
      marker = @ledger.dig("preflight", "public_marker")
      pack = @ledger.fetch("pack", {})
      preflight = @ledger.fetch("preflight", {})
      valid = marker.is_a?(Hash) && marker["status"] == "unique" &&
              marker["pack_id"] == pack["pack_id"] &&
              marker["candidate"] == pack["candidate"] &&
              marker["candidate_commit"] == pack["candidate_commit"] &&
              marker["snapshot_fingerprint"] == pack["snapshot_fingerprint"] &&
              marker["opened_at"] == preflight["opened_at"] &&
              present?(marker["evidence"])
      return if valid

      "public preflight marker is not unique and snapshot-bound"
    end

    def valid_waiver?(waiver, expected_gate)
      waiver.is_a?(Hash) && waiver["gate"] == expected_gate &&
        %w[authority evidence_url reason].all? { |field| present?(waiver[field]) }
    end

    def preflight_gate_passed?(gate)
      gate.is_a?(Hash) && gate["status"] == "passed" && present?(gate["evidence"])
    end

    def timestamp(value)
      return unless value.to_s.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)

      Time.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def terminal_preflight_waiver?(preflight, waiver)
      gate = waiver["gate"] if waiver.is_a?(Hash)
      if %w[release_ci generator_matrix].include?(gate)
        valid_preflight_waiver?(waiver, gate, preflight[gate])
      elsif gate.to_s.start_with?("capabilities.")
        field = gate.delete_prefix("capabilities.")
        valid_preflight_capability_waiver?(waiver, field, preflight.dig("capabilities", field))
      else
        false
      end
    end

    def valid_preflight_waiver?(waiver, field, gate)
      valid_waiver?(waiver, field) && gate.is_a?(Hash) &&
        %w[blocked waived].include?(gate["status"]) && present?(gate["evidence"])
    end

    def valid_preflight_capability_waiver?(waiver, field, status)
      valid_waiver?(waiver, "capabilities.#{field}") && %w[blocked waived].include?(status)
    end

    def release_blocked?
      hard_gate_blocked = Array(@ledger["inventory"]).any? do |item|
        next false unless item["tier"] == "hard_gate"

        top_level_blocked = !%w[passed waived].include?(item["result"]) || item["work_state"] == "blocked"
        check_blocked = item.fetch("checks", {}).values.any? { |check| check["status"] == "blocked" }
        candidate_regression = item.dig("baseline", "classification") == "candidate_regression"
        unwaived_baseline_defect = item.dig("baseline", "classification") == "baseline_defect" &&
                                   !valid_waiver?(item.dig("baseline", "waiver"), "#{item['id']}:baseline")
        review_app_blocked = item.dig("review_app", "state") == "configured_broken" ||
                             item.dig("review_app", "deployed_smoke") == "blocked"
        top_level_blocked || check_blocked || candidate_regression || unwaived_baseline_defect ||
          review_app_blocked
      end
      required_path_blocked = @required_paths.any? do |required|
        path = Array(@ledger["required_paths"]).find { |item| item["id"] == required.fetch("id") }
        !%w[passed waived].include?(path&.fetch("status", nil))
      end
      soft_only_blockers = BlockerScope.soft_only_ids(@ledger)
      active_blocker = Array(@ledger["blockers"]).any? do |blocker|
        !%w[resolved waived deferred].include?(blocker["status"]) &&
          !soft_only_blockers.include?(blocker["id"])
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
        "boolean" => [TrueClass, FalseClass],
        "integer" => Integer,
        "null" => NilClass,
        "object" => Hash,
        "string" => String
      }.fetch(type).then { |klass| Array(klass).any? { |candidate| value.is_a?(candidate) } }
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
        review_app_blocked = item.dig("review_app", "state") == "configured_broken" ||
                             item.dig("review_app", "deployed_smoke") == "blocked"
        baseline = item.fetch("baseline", {})
        unwaived_baseline_defect = baseline["classification"] == "baseline_defect" &&
                                   !structured_waiver?(baseline["waiver"], "#{item['id']}:baseline")
        top_level_blocked || check_blocked || candidate_regression || unwaived_baseline_defect ||
          review_app_blocked
      end
      blocked ||= paths.any? { |path| !%w[passed waived].include?(path["status"]) }
      soft_only_blockers = BlockerScope.soft_only_ids(@ledger)
      blocked ||= blockers.any? do |blocker|
        !%w[resolved waived deferred].include?(blocker["status"]) &&
          !soft_only_blockers.include?(blocker["id"])
      end
      blocked ||= @ledger.dig("tracker", "promotion") == "blocked"
      return "BLOCKED" if blocked

      partial = inventory.any? do |item|
        target_waived = item["result"] == "waived"
        check_waived = item.fetch("checks", {}).values.any? { |check| check["status"] == "waived" }
        baseline_waived = item.dig("baseline", "classification") == "waived"
        baseline_defect = item.dig("baseline", "classification") == "baseline_defect"
        review_app_waived = item.dig("review_app", "deployed_smoke") == "waived" &&
                            item.dig("review_app", "state") != "not_configured"
        target_waived || check_waived || baseline_waived || baseline_defect || review_app_waived ||
          (item["tier"] == "soft_track" && item["result"] == "blocked")
      end
      partial ||= @ledger.dig("preflight", "status") == "waived"
      partial ||= %w[release_ci artifacts generator_matrix].any? do |gate|
        @ledger.dig("preflight", gate, "status") == "waived"
      end
      partial ||= paths.any? { |path| path["status"] == "waived" }
      partial ||= blockers.any? do |blocker|
        %w[waived deferred].include?(blocker["status"]) ||
          (soft_only_blockers.include?(blocker["id"]) &&
            !%w[resolved waived deferred].include?(blocker["status"]))
      end
      partial ||= @ledger.dig("tracker", "promotion") == "hold"

      partial ? "PARTIAL" : "PASS"
    end

    def escape(value)
      value.to_s.gsub(/\s+/, " ").strip.gsub("|", "\\|").gsub("<!--", "&lt;!--").gsub("-->", "--&gt;")
    end

    def structured_waiver?(waiver, gate)
      waiver.is_a?(Hash) && waiver["gate"] == gate &&
        %w[authority evidence_url reason].all? { |field| !waiver[field].to_s.empty? }
    end
  end
end
