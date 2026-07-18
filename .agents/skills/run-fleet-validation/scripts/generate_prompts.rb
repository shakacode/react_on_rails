#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "optparse"
require "securerandom"
require "yaml"
require_relative "fleet_lifecycle"

module FleetValidation
  CORE_GATE = {
    "name" => "react_on_rails generator/install smoke",
    "headline" => "Monorepo generator and install smoke",
    "kind" => "core",
    "weight" => 5
  }.freeze

  class Generator
    attr_reader :assignments, :lifecycle_inventory, :required_paths

    def initialize(manifest_path:, prompt_count:, machines:, release_selector:, pack_id: nil)
      @manifest_path = manifest_path
      @prompt_count = prompt_count
      @machines = machines
      @release_selector = release_selector
      @pack_id = pack_id || default_pack_id
      @manifest = load_manifest
      validate_options!
      @lifecycle = Lifecycle.new(manifest: @manifest, pack_id: @pack_id, release_selector: @release_selector)
      @lifecycle_inventory = @lifecycle.inventory
      @required_paths = @lifecycle.required_paths
      @targets = build_targets
      validate_target_ids!
      @assignments = assign_machines(build_lanes)
    end

    def render_pack
      sections = ordered_assignments.map.with_index(1) do |assignment, index|
        <<~MARKDOWN
          ## Prompt #{index} — #{assignment.fetch(:machine)}

          ```text
          #{render_prompt(assignment, index).rstrip}
          ```
        MARKDOWN
      end

      <<~MARKDOWN
        # Fleet validation prompt pack

        Pack ID: #{@pack_id}
        Release selector: #{@release_selector}
        Manifest: #{@manifest_path}
        Layout: #{@prompt_count} simultaneous prompts across #{@machines.length} machines

        #{machine_summary}

        #{sections.join("\n")}
      MARKDOWN
    end

    def ledger_template
      @lifecycle.ledger_template
    end

    def ledger_schema
      @lifecycle.schema
    end

    def write_pack(output_dir)
      FileUtils.mkdir_p(output_dir)
      clear_generated_prompts(output_dir)
      rendered_prompts = []

      ordered_assignments.each_with_index do |assignment, offset|
        number = offset + 1
        machine_slug = slug(assignment.fetch(:machine))
        directory = File.join(output_dir, machine_slug)
        FileUtils.mkdir_p(directory)
        filename = format("%02d-fleet-lane.md", number)
        relative_path = File.join(machine_slug, filename)
        File.write(File.join(output_dir, relative_path), render_prompt(assignment, number))
        rendered_prompts << [assignment.fetch(:machine), relative_path, assignment]
      end

      File.write(File.join(output_dir, "INDEX.md"), render_index(rendered_prompts))
      @lifecycle.write_artifacts(output_dir)
    end

    private

    def clear_generated_prompts(output_dir)
      pattern = File.join(output_dir, "*", "*-fleet-lane.md")
      FileUtils.rm_f(Dir.glob(pattern))
    end

    def load_manifest
      manifest = YAML.safe_load_file(@manifest_path, permitted_classes: [], permitted_symbols: [], aliases: false)
      raise ManifestError, "manifest root must be a mapping" unless manifest.is_a?(Hash)

      manifest
    rescue Errno::ENOENT
      raise ManifestError, "manifest not found: #{@manifest_path}"
    rescue Psych::Exception => e
      raise ManifestError, "invalid manifest YAML: #{e.message}"
    end

    def validate_options!
      raise ManifestError, "schema_version must be 1" unless @manifest["schema_version"] == 1
      raise ManifestError, "repos must be an array" unless @manifest["repos"].is_a?(Array)

      validate_repo_entries!
      raise ManifestError, "--prompts must be positive" unless @prompt_count.positive?
      raise ManifestError, "--machines must name at least one machine" if @machines.empty?
      raise ManifestError, "--machines cannot exceed --prompts" if @machines.length > @prompt_count
      raise ManifestError, "machine names must be unique" unless @machines.uniq.length == @machines.length
      raise ManifestError, "machine names must have non-empty path slugs" if @machines.any? { |name| slug(name).empty? }
      raise ManifestError, "machine names must have unique path slugs" unless @machines.map { |name| slug(name) }.uniq.length == @machines.length
      unless @pack_id.match?(/\A[a-z0-9][a-z0-9._-]*\z/i)
        raise ManifestError, "pack ID must contain only letters, digits, dots, underscores, and hyphens"
      end

      target_count = @manifest["repos"].count { |repo| repo["tier"] == "hard_gate" } + 1
      minimum_prompts = (target_count.to_f / 2).ceil
      if @prompt_count < minimum_prompts
        raise ManifestError, "--prompts must be at least #{minimum_prompts} to keep at most two targets per lane"
      end
      return if @prompt_count <= target_count

      raise ManifestError, "--prompts #{@prompt_count} exceeds #{target_count} available hard-gate targets"
    end

    def validate_repo_entries!
      defaults = @manifest.fetch("defaults", {})
      raise ManifestError, "defaults must be a mapping" unless defaults.is_a?(Hash)

      @manifest.fetch("repos").each_with_index do |repo, index|
        raise ManifestError, "repos[#{index}] must be a mapping" unless repo.is_a?(Hash)

        next unless repo["tier"] == "hard_gate"

        validate_hard_gate_repo!(defaults.merge(repo), index)
      end
    end

    def validate_hard_gate_repo!(repo, index)
      %w[name headline package_manager ruby_test build].each do |field|
        value = repo[field]
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          raise ManifestError, "repos[#{index}] hard gate is missing #{field}"
        end
        next if value.is_a?(String)

        raise ManifestError, "repos[#{index}] hard gate #{field} must be a string"
      end
      unless [true, false].include?(repo["needs_pro"])
        raise ManifestError, "repos[#{index}] hard gate needs_pro must be true or false"
      end

      validate_repo_collection!(repo, index, "packages")
      validate_repo_collection!(repo, index, "smoke")
      unless repo.fetch("smoke").all? { |path| path.is_a?(String) && !path.empty? }
        raise ManifestError, "repos[#{index}] hard gate smoke entries must be non-empty strings"
      end

      repo.fetch("packages").each_with_index do |package, package_index|
        unless package.is_a?(Hash) && package["ecosystem"].to_s != "" && package["name"].to_s != ""
          raise ManifestError, "repos[#{index}].packages[#{package_index}] must name an ecosystem and package"
        end
      end
    end

    def validate_repo_collection!(repo, index, field)
      return if repo[field].is_a?(Array)

      raise ManifestError, "repos[#{index}] hard gate #{field} must be an array"
    end

    def build_targets
      defaults = @manifest.fetch("defaults", {})
      repos = @manifest.fetch("repos").select { |repo| repo["tier"] == "hard_gate" }
      [CORE_GATE] + repos.map { |repo| effective_repo(defaults, repo) }
    end

    def validate_target_ids!
      ids = @targets.map { |target| stable_target_id(target) }
      raise ManifestError, "target names must have non-empty stable IDs" if ids.any?(&:empty?)

      duplicates = ids.tally.select { |_id, count| count > 1 }.keys
      return if duplicates.empty?

      raise ManifestError, "target names must have unique stable IDs: #{duplicates.join(', ')}"
    end

    def effective_repo(defaults, repo)
      effective = defaults.merge(repo)
      effective["kind"] = "repo"
      effective["weight"] = repo_weight(effective)
      effective
    end

    def repo_weight(repo)
      weight = 2
      weight += 2 if repo["needs_pro"]
      weight += 2 if repo.fetch("name").end_with?("/hichee")
      weight += 1 if repo.fetch("packages", []).length >= 8
      weight += 1 if repo["package_manager"].to_s.start_with?("yarn")
      weight += 1 if repo.fetch("smoke", []).length > 1
      weight
    end

    def build_lanes
      lanes = Array.new(@prompt_count) { { targets: [], weight: 0 } }
      @targets.sort_by { |target| [-target.fetch("weight"), target.fetch("name")] }.each do |target|
        eligible_lanes = lanes.select { |item| item.fetch(:targets).length < 2 }
        lane = eligible_lanes.min_by { |item| [item.fetch(:weight), item.fetch(:targets).length] }
        lane.fetch(:targets) << target
        lane[:weight] += target.fetch("weight")
      end
      lanes
    end

    def assign_machines(lanes)
      capacity = (@prompt_count.to_f / @machines.length).ceil
      machine_state = @machines.to_h { |machine| [machine, { count: 0, weight: 0 }] }

      lanes.sort_by { |lane| -lane.fetch(:weight) }.map do |lane|
        eligible = @machines.select { |machine| machine_state.fetch(machine).fetch(:count) < capacity }
        machine = eligible.min_by do |candidate|
          state = machine_state.fetch(candidate)
          [state.fetch(:weight), state.fetch(:count), @machines.index(candidate)]
        end
        state = machine_state.fetch(machine)
        state[:count] += 1
        state[:weight] += lane.fetch(:weight)
        lane.merge(machine:)
      end
    end

    def ordered_assignments
      assignments.sort_by do |assignment|
        [@machines.index(assignment.fetch(:machine)), -assignment.fetch(:weight)]
      end
    end

    def machine_summary
      rows = ordered_assignments.group_by { |assignment| assignment.fetch(:machine) }.map do |machine, lanes|
        targets = lanes.flat_map { |lane| lane.fetch(:targets).map { |target| target.fetch("name") } }
        "- #{machine}: #{lanes.length} prompts; #{targets.join(', ')}"
      end
      (["## Machine allocation", ""] + rows).join("\n")
    end

    def render_index(rendered_prompts)
      rows = rendered_prompts.map do |machine, path, assignment|
        targets = assignment.fetch(:targets).map { |target| target.fetch("name") }.join("; ")
        "| #{machine} | [#{File.basename(path)}](#{path}) | #{targets} |"
      end

      <<~MARKDOWN
        # Fleet validation launch index

        1. Run [PREFLIGHT.md](PREFLIGHT.md) and record its results in `result-ledger.json`.
        2. Start all #{@prompt_count} prompt coordinators simultaneously after the snapshot exists.
           Do not start the app mutation prompts before `APP_WORK_ALLOWED`; coordinators may prepare
           read-only evidence while waiting.
        3. Run [REPORT-ONLY.md](REPORT-ONLY.md) for the complete soft-track inventory.
        4. Run [CLOSEOUT.md](CLOSEOUT.md) with an independent checker, validate `result-ledger.json`
           against `result-ledger.schema.json`, and render the tracker matrix from that ledger.

        This layout runs at most
        #{(@prompt_count.to_f / @machines.length).ceil} prompts on one machine; use the exact allocation
        below. Do not share mutable app checkouts between prompts.

        Release selector: #{@release_selector}
        Pack ID: #{@pack_id}

        | Machine | Prompt | Targets |
        | --- | --- | --- |
        #{rows.join("\n")}
      MARKDOWN
    end

    def render_prompt(assignment, number)
      targets = assignment.fetch(:targets)
      <<~PROMPT
        You are fleet-validation coordinator #{number} running on #{assignment.fetch(:machine)}.
        Pack ID: #{@pack_id}
        Validate the assigned React on Rails release gates for #{@release_selector}. Work autonomously
        through evidence collection and safe fixes; do not merge or make the final release decision.

        Release resolution:
        #{candidate_resolution_steps(number)}
        #{tracker_resolution_steps(number)}
        #{snapshot_resolution_steps(number)}

        Assigned targets:
        #{targets.map { |target| render_target(target) }.join("\n")}

        Subagent plan (required):
        1. Spawn one read-only evidence subagent covering all assigned targets. It must inspect the
           tracker, targeted coordination state, existing bump PRs, required checks, and repo-local
           instructions, then return a passed/blocked/pending/unknown matrix with links. It must not edit
           or post.
        2. Before starting a mutable app worker, acquire or resume its authoritative `agent-coord` claim
           under the candidate-specific batch/target recorded in live coordination. If no lane exists for
           a fresh target, use its generated fallback claim target shown below. Never use the fallback to
           bypass an active/refused existing claim or completed handoff. Follow
           `.agents/workflows/pr-processing.md`: targeted status is preflight only; the claim is the
           compare-and-swap gate. Hard-stop that target on CLAIM_REFUSED. On claim timeout or unknown
           outcome, report UNKNOWN and do not create a branch/worktree. Resume another owner's work only
           through an explicit fenced handoff. Replace `RESOLVED_TAG` in a fallback template with the exact
           tag before status/claim and use the displayed fallback claim repository; never submit the
           template literally. Heartbeat successful claims at phase transitions.
        3. Concurrently spawn one execution subagent for the assigned monorepo generator/install gate,
           if present, plus one per successfully claimed app target (maximum #{targets.length} here). The
           monorepo worker needs no app claim and runs the local checkout commands plus the published
           three-mode matrix in an isolated scratch directory. Every app worker uses its own scratch
           clone/worktree, validates or updates the existing release bump, runs the effective
           install/build/test/smoke ladder, and prepares exact public-safe evidence.
           Child agents must not spawn more agents.
        4. As coordinator, reconcile their reports against live current-head state. Re-run cheap checks
           needed to resolve disagreement. Never convert missing evidence into a pass.

        Execution contract:
        - Do not start app mutation work until `APP_WORK_ALLOWED` is present in the pack-specific
          release-wide preflight ledger. The marker is valid only when release commit CI, published
          artifacts, and the standard / Pro / Pro+RSC generator matrix are terminal green, or when
          an explicit public-safe waiver names the failed gate and authority.
        - Read AGENTS.md and repository-specific instructions before changing any target repo. Treat the
          manifest commands as starting data; because `verify: true` entries are provisional, confirm
          commands against the target before running or proposing a manifest correction.
        - For app targets, reuse or update an existing bump PR for this candidate. If none exists, create
          a feature branch and PR only after local install/build checks pass. Never push directly to a
          default branch. The monorepo generator/install gate is read-only validation of published
          artifacts: do not create a bump branch or PR for it.
        - Capture dependency install, intentional lockfile diff, build/assets, target tests, required CI,
          primary route smoke, SSR/hydration, and the target's headline Pro/RSC behavior where applicable.
          When review-app metadata is null/unverified, derive a repo-owned local boot/smoke command from
          target docs; do not invent a public deployment URL or claim hosted review-app smoke.
        - A confirmed candidate regression is BLOCKED and needs a linked issue. Unrelated failures remain
          PENDING until an allowed tracker waiver exists. Lane 4b artifact defects cannot be waived.
        - For HiChee or Pro/private material, never paste private logs, URLs, screenshots, credentials, or
          proprietary diffs. Public evidence is limited to high-level result, tester, date, and public issue.
        - Post or update one tracker comment per target, using the exact resolved tag plus the stable
          target ID shown below. The marker format is
          `<!-- fleet-validation:<resolved-tag>:<stable-target-id> -->`; substitute the actual values and
          never post the angle-bracket placeholders literally. Do not concurrently rewrite the tracker
          body.

        Stable evidence IDs:
        #{targets.map { |target| "- #{target.fetch('name')}: #{stable_target_id(target)}" }.join("\n")}

        Final response:
        - Resolved release identifiers and tracking issue.
        - One row per target: PASSED / BLOCKED / PENDING / UNKNOWN, PR, current-head CI, smoke evidence,
          blocker/waiver link, and next owner/action.
        - Any manifest fields proven stale, with an exact proposed YAML patch.
        - A lane verdict. Say explicitly whether this lane blocks promotion; do not infer the whole-fleet
          go/no-go decision.
      PROMPT
    end

    def render_target(target)
      return render_core_target(target) if target["kind"] == "core"

      packages = target.fetch("packages", []).map do |package|
        "#{package.fetch('ecosystem')}:#{package.fetch('name')}"
      end.join(", ")
      review_app = target["review_app"]
      review_app_fields = if review_app.is_a?(Hash)
                            "workflow=#{review_app['workflow'] || 'unverified'}, " \
                              "status_check=#{review_app['status_check'] || 'unverified'}, " \
                              "cpflow_app_name=#{review_app['cpflow_app_name'] || 'none/unverified'}"
                          else
                            "none/unverified"
                          end

      <<~TARGET.chomp
        - #{target.fetch('name')} — #{target.fetch('headline')}
          packages: #{packages}
          needs_pro: #{target.fetch('needs_pro')}; package_manager: #{target.fetch('package_manager')}
          fallback_claim_repo: shakacode/react_on_rails
          fallback_claim_target_template: adhoc:fleet-RESOLVED_TAG-#{stable_target_id(target)}
          install: #{install_command(target.fetch('package_manager'))}
          ruby_test: #{target.fetch('ruby_test')}; js_test: #{target['js_test'] || 'none'}
          build: #{target.fetch('build')}; smoke: #{target.fetch('smoke', []).join(', ')}
          review_app: #{review_app_fields}; verify: #{target.fetch('verify', false)}
      TARGET
    end

    def render_core_target(target)
      <<~TARGET.chomp
        - #{target.fetch('name')} — #{target.fetch('headline')}
          In a clean checkout at the resolved tag, run the local generator/build smoke:
          `(cd react_on_rails && bundle exec rspec spec/react_on_rails/generators)`
          `pnpm run build`
          `CREATE_ROR_SMOKE_SCOPE=oss packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh`
          Then, in a separate scratch directory with no local package or gem overrides, replace
          `RESOLVED_NPM_VERSION` with the exact normalized candidate version and run the published matrix:
          `npx --yes create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-standard --standard`
          `npx --yes create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-pro`
          `npx --yes create-react-on-rails-app@RESOLVED_NPM_VERSION fleet-rsc --rsc`
          Never submit the placeholder literally. Install/build/smoke all three generated apps. Assert the
          standard app is core-only, the default app has working Pro SSR without RSC, and the RSC app is
          streamed and interactive. Verify exact candidate gem/npm locks in every applicable app and the
          independently resolved RSC version only in the RSC app. Keep Pro/RSC logs private.
          This gate is validation-only. Do not create a branch or PR, and do not substitute fleet app CI.
      TARGET
    end

    def candidate_resolution_steps(number)
      return "" unless number == 1

      <<~STEPS.chomp
        - You are the release-snapshot leader. Resolve #{@release_selector} once from authoritative
          published `react_on_rails`, `react_on_rails_pro`, `react-on-rails`, `react-on-rails-pro`,
          `react-on-rails-pro-node-renderer`, and `create-react-on-rails-app` packages plus the matching git
          tag. Normalize RubyGems/npm RC or beta spelling before comparison and derive the release line from
          that exact tag before selecting a tracker. Under `shakacode/react_on_rails`, acquire the
          coordination snapshot claim `adhoc:fleet-snapshot-RESOLVED_TAG` after replacing `RESOLVED_TAG`
          with the exact tag. Never submit the template literally; a refused claim is a hard stop.
      STEPS
    end

    def snapshot_resolution_steps(number)
      if number == 1
        <<~STEPS.chomp
          - Derive the independently released `react-on-rails-rsc` version separately from the tagged
            product manifests and the release tracker, then verify that exact RSC artifact is published.
            Never require it to share the React on Rails product version.
          - Post one tracker snapshot comment marked `<!-- fleet-validation-snapshot:#{@pack_id} -->` with
            the exact tag, normalized gem/npm product versions, RSC version, commit SHA, and resolution time.
            Heartbeat/close the snapshot claim only after the public-safe comment is readable.
        STEPS
      else
        <<~STEPS.chomp
          - Do not select a candidate independently. Wait up to five minutes for the tracker comment marked
            `<!-- fleet-validation-snapshot:#{@pack_id} -->` from coordinator 1, then use its exact tag,
            product gem/npm versions, independently versioned RSC pin, and commit SHA for the whole lane.
            Cross-check those artifacts and tag before mutation. If the snapshot is absent, malformed, or
            inconsistent, report UNKNOWN and make no writes.
        STEPS
      end
    end

    def tracker_resolution_steps(number)
      if number != 1
        <<~STEPS.chomp
          - Do not choose a release line first. Search the open `Release gate: react_on_rails X.Y.Z`
            tracker issues for the exact `<!-- fleet-validation-snapshot:#{@pack_id} -->` marker. Wait up
            to five minutes for one unique match; the issue containing it is this lane's tracker. If the
            marker is absent or appears in multiple trackers, report UNKNOWN and make no writes.
        STEPS
      elsif @release_selector == "latest RC or beta"
        <<~STEPS.chomp
          - Find the open `Release gate: react_on_rails X.Y.Z` tracking issue for that release line. Do not
            create a second tracker. A tracker spans multiple candidates: use its newest explicit RC section
            or comment and targeted coordination status, not an older version still present in the issue body.
            If the current candidate has no authoritative entry or live sources conflict, stop writes and
            report UNKNOWN with evidence.
        STEPS
      else
        <<~STEPS.chomp
          - Find the open `Release gate: react_on_rails X.Y.Z` tracking issue for the release line containing
            the pinned #{@release_selector} candidate. Do not create a second tracker. Use only the exact
            candidate's section/comments plus targeted coordination state for candidate evidence. Newer
            candidate entries are context and must not override the pinned selector. If authoritative
            artifacts or the matching tag conflict with the pinned selector, stop writes and report UNKNOWN.
        STEPS
      end
    end

    def install_command(package_manager)
      {
        "npm" => "npm ci",
        "pnpm" => "pnpm install --frozen-lockfile",
        "yarn_classic" => "yarn install --frozen-lockfile",
        "yarn_berry" => "yarn install --immutable"
      }.fetch(package_manager, "derive from the target repo")
    end

    def stable_target_id(target)
      slug(target.fetch("name"))
    end

    def default_pack_id
      "fleet-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{SecureRandom.hex(3)}"
    end

    def slug(value)
      value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end
  end

  module CLI
    module_function

    def run(argv)
      options = {
        manifest_path: "internal/contributor-info/demo-fleet.yml",
        prompt_count: 6,
        machines: %w[local m1],
        release_selector: "latest RC or beta",
        pack_id: nil,
        output_dir: nil
      }
      parser = option_parser(options)
      parser.parse!(argv)

      generator = Generator.new(
        **options.slice(:manifest_path, :prompt_count, :machines, :release_selector, :pack_id)
      )
      if options[:output_dir]
        generator.write_pack(options[:output_dir])
        puts "Wrote #{options[:prompt_count]} prompts to #{options[:output_dir]}"
      else
        puts generator.render_pack
      end
      0
    rescue ManifestError, OptionParser::ParseError => e
      warn "ERROR: #{e.message}"
      warn parser
      1
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: generate_prompts.rb [options]"
        parser.on("--manifest PATH", "Fleet manifest path") { |value| options[:manifest_path] = value }
        parser.on("--prompts COUNT", Integer, "Number of simultaneous prompts") do |value|
          options[:prompt_count] = value
        end
        parser.on("--machines NAMES", "Comma-separated machine names") do |value|
          options[:machines] = value.split(",").map(&:strip).reject(&:empty?)
        end
        parser.on("--release SELECTOR", "Release tag or dynamic selector") do |value|
          options[:release_selector] = value
        end
        parser.on("--pack-id ID", "Reuse an existing generated pack ID") { |value| options[:pack_id] = value }
        parser.on("--output-dir PATH", "Write prompt files and INDEX.md") { |value| options[:output_dir] = value }
        parser.on("-h", "--help", "Show help") do
          puts parser
          exit 0
        end
      end
    end
  end
end

exit FleetValidation::CLI.run(ARGV) if $PROGRAM_NAME == __FILE__
