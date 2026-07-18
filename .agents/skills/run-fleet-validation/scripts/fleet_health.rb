# frozen_string_literal: true

require "fileutils"
require "json"
require "rubygems/version"
require "time"
require "uri"
require "yaml"
require_relative "fleet_lifecycle"

module FleetValidation
  class PublicRegistryResolver
    RUBYGEMS = "https://rubygems.org"
    NPM = "https://registry.npmjs.org"
    PRODUCT_GEMS = %w[react_on_rails react_on_rails_pro].freeze
    PRODUCT_NPM = %w[
      react-on-rails
      react-on-rails-pro
      react-on-rails-pro-node-renderer
      create-react-on-rails-app
    ].freeze
    RSC_NPM = "react-on-rails-rsc"

    def initialize(fetcher:)
      @fetcher = fetcher
    end

    def resolve(release:, rsc_version:)
      product_version = release.delete_prefix("v")
      gem_artifacts = PRODUCT_GEMS.map do |name|
        versions = @fetcher.call("#{RUBYGEMS}/api/v1/versions/#{name}.json")
        unless Array(versions).any? { |entry| entry["number"] == product_version && entry["yanked"] != true }
          raise ManifestError, "#{name} #{product_version} is not a public non-yanked RubyGems artifact"
        end

        registry_artifact("gem", name, product_version, RUBYGEMS)
      end
      npm_artifacts = PRODUCT_NPM.map do |name|
        document = @fetcher.call("#{NPM}/#{name}")
        unless document.fetch("versions", {}).key?(product_version)
          raise ManifestError, "#{name} #{product_version} is not a public npm artifact"
        end

        registry_artifact("npm", name, product_version, NPM)
      end
      npm_rsc = @fetcher.call("#{NPM}/#{RSC_NPM}")
      unless npm_rsc.fetch("versions", {}).key?(rsc_version)
        raise ManifestError, "#{RSC_NPM} #{rsc_version} is not a public npm artifact"
      end

      gem_artifacts + npm_artifacts + [registry_artifact("npm", RSC_NPM, rsc_version, NPM)]
    end

    private

    def registry_artifact(ecosystem, name, version, source)
      {
        "ecosystem" => ecosystem,
        "name" => name,
        "version" => version,
        "source" => source
      }
    end
  end

  module PublicSBOM
    module_function

    def package_versions(document)
      sbom = document["sbom"]
      return [] unless sbom.is_a?(Hash)

      direct_ids = direct_dependency_ids(sbom)
      return [] if direct_ids.empty?

      versions = Array(sbom["packages"]).filter_map do |package|
        next unless direct_ids.include?(package["SPDXID"])

        purl = Array(package["externalRefs"]).find { |reference| reference["referenceType"] == "purl" }
        parse_purl(purl && purl["referenceLocator"])
      end
      versions.uniq { |package| [package["ecosystem"], package["name"], package["version"]] }
    end

    def direct_dependency_ids(sbom)
      document_id = sbom["SPDXID"]
      return [] if document_id.to_s.empty?

      relationships = Array(sbom["relationships"])
      root_ids = relationships.filter_map do |relationship|
        relationship["relatedSpdxElement"] if relationship["spdxElementId"] == document_id &&
                                              relationship["relationshipType"] == "DESCRIBES"
      end
      return [] if root_ids.empty?

      relationships.filter_map do |relationship|
        relationship["relatedSpdxElement"] if root_ids.include?(relationship["spdxElementId"]) &&
                                              relationship["relationshipType"] == "DEPENDS_ON"
      end.uniq
    end

    def parse_purl(value)
      match = value.to_s.match(%r{\Apkg:(gem|npm)/(.+)@([^?]+)})
      return unless match

      {
        "ecosystem" => match[1],
        "name" => URI.decode_www_form_component(match[2]),
        "version" => URI.decode_www_form_component(match[3]),
        "source" => "github-sbom"
      }
    end
  end

  module DependabotV1
    module_function

    ECOSYSTEMS = {
      "gem" => "bundler",
      "npm" => "npm"
    }.freeze

    def evaluate(config, packages)
      findings = []
      unless config.is_a?(Hash) && config["version"] == 2 && config["updates"].is_a?(Array)
        return { "status" => "blocked", "findings" => ["invalid-config"] }
      end

      required = Array(packages).filter_map { |package| ECOSYSTEMS[package["ecosystem"]] }.uniq
      required << "github-actions"
      required.each do |ecosystem|
        entries = config.fetch("updates").select { |entry| entry["package-ecosystem"] == ecosystem }
        if entries.empty?
          findings << "#{ecosystem}:missing"
          next
        end

        findings << "#{ecosystem}:not-weekly" unless entries.any? { |entry| entry.dig("schedule", "interval") == "weekly" }
        if entries.all? { |entry| entry.fetch("open-pull-requests-limit", 1).zero? }
          findings << "#{ecosystem}:version-updates-disabled"
        end
        next if ecosystem == "github-actions"

        patterns = entries.flat_map do |entry|
          entry.fetch("groups", {}).values.flat_map { |group| Array(group["patterns"]) }
        end
        expected_prefix = ecosystem == "bundler" ? "react_on_rails" : "react-on-rails"
        unless patterns.any? { |pattern| pattern.start_with?(expected_prefix) }
          findings << "#{ecosystem}:product-group-missing"
        end
      end

      {
        "status" => findings.empty? ? "passed" : "blocked",
        "findings" => findings
      }
    end
  end

  class PublicGitHubProbe
    SHARED_SMOKE_REFERENCE = "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@"
    PASSING_CONCLUSIONS = %w[success neutral skipped].freeze

    def initialize(client:)
      @client = client
    end

    def observe(target, observed_at:)
      repo = target.fetch("name")
      metadata = @client.get("/repos/#{repo}")
      default_branch = metadata.fetch("default_branch")
      commit = @client.get("/repos/#{repo}/commits/#{default_branch}")
      head = commit.fetch("sha")
      checks = @client.get("/repos/#{repo}/commits/#{head}/check-runs?per_page=100").fetch("check_runs", [])
      workflows = @client.get("/repos/#{repo}/actions/workflows?per_page=100").fetch("workflows", [])

      {
        "default_branch" => default_branch,
        "default_commit" => head,
        "default_commit_at" => commit.dig("commit", "committer", "date"),
        "observed_at" => observed_at,
        "package_versions" => package_versions(repo),
        "default_ci" => check_status(checks),
        "smoke" => smoke_status(repo, head, checks, workflows),
        "review_app" => review_app_status(repo, target, workflows),
        "dependabot" => dependabot_status(repo, head, target.fetch("packages"))
      }
    rescue StandardError => e
      unknown_observation(observed_at, e.message)
    end

    private

    def package_versions(repo)
      PublicSBOM.package_versions(@client.get("/repos/#{repo}/dependency-graph/sbom"))
    rescue StandardError
      []
    end

    def check_status(checks)
      return evidence_status("unknown", "No current-head check runs found") if checks.empty?

      pending = checks.any? { |check| check["status"] != "completed" }
      failures = checks.reject do |check|
        check["status"] == "completed" && PASSING_CONCLUSIONS.include?(check["conclusion"])
      end
      status = if pending
                 "unknown"
               elsif failures.empty?
                 "passed"
               else
                 "blocked"
               end
      evidence_status(status, evidence_urls(checks))
    end

    def smoke_status(repo, head, checks, workflows)
      smoke_workflows = workflows.select { |workflow| smoke_name?(workflow["name"]) || smoke_name?(workflow["path"]) }
      smoke_checks = checks.select { |check| smoke_name?(check["name"]) }
      status = check_status(smoke_checks)
      shared_contract = smoke_workflows.any? do |workflow|
        @client.content(repo, workflow.fetch("path"), ref: head).include?(SHARED_SMOKE_REFERENCE)
      rescue StandardError
        false
      end
      status.merge(
        "shared_contract" => shared_contract,
        "evidence" => [status["evidence"], smoke_workflows.map { |workflow| workflow["path"] }.join(", ")]
          .reject { |value| value.to_s.empty? }.join("; ")
      )
    end

    def review_app_status(repo, target, workflows)
      if target.fetch("review_app") == "not_required"
        return evidence_status("not_applicable", "Review app is not required by public fleet policy")
      end

      workflow_path = target["review_app_workflow"]
      unless workflow_path.is_a?(String) && !workflow_path.empty?
        return evidence_status("unknown", "Required review-app workflow path is not configured")
      end

      workflow = workflows.find { |candidate| candidate["path"] == workflow_path }
      return evidence_status("unknown", "Configured review-app workflow was not found: #{workflow_path}") unless workflow

      review_workflow_status(repo, workflow)
    end

    def review_workflow_status(repo, workflow)
      workflow_evidence = workflow["html_url"] || workflow["path"]
      unless workflow["state"] == "active"
        return evidence_status("blocked", "#{workflow_evidence}; state=#{workflow['state'] || 'unknown'}")
      end

      workflow_id = workflow.fetch("id")
      runs = @client.get("/repos/#{repo}/actions/workflows/#{workflow_id}/runs?per_page=1")
                    .fetch("workflow_runs", [])
      return evidence_status("unknown", "#{workflow_evidence}; no public workflow run") if runs.empty?

      run = runs.first
      evidence = [
        workflow_evidence,
        run["html_url"],
        ("updated_at=#{run['updated_at']}" if run["updated_at"])
      ].compact.join("; ")
      return evidence_status("unknown", evidence) unless run["status"] == "completed"

      status = PASSING_CONCLUSIONS.include?(run["conclusion"]) ? "passed" : "blocked"
      evidence_status(status, evidence)
    rescue StandardError => e
      evidence_status("unknown", "#{workflow_evidence}; workflow run unavailable: #{e.class}")
    end

    def dependabot_status(repo, head, packages)
      content = @client.content(repo, ".github/dependabot.yml", ref: head)
      config = YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)
      result = DependabotV1.evaluate(config, packages)
      {
        "status" => result.fetch("status"),
        "policy" => "v1",
        "evidence" => result.fetch("findings").empty? ? ".github/dependabot.yml" : result.fetch("findings").join(", ")
      }
    rescue StandardError => e
      {
        "status" => "blocked",
        "policy" => "v1",
        "evidence" => "Dependabot v1 config unavailable: #{e.class}"
      }
    end

    def unknown_observation(observed_at, reason)
      {
        "default_branch" => nil,
        "default_commit" => nil,
        "default_commit_at" => nil,
        "observed_at" => observed_at,
        "package_versions" => [],
        "default_ci" => evidence_status("unknown", reason),
        "smoke" => evidence_status("unknown", reason).merge("shared_contract" => false),
        "review_app" => evidence_status("unknown", reason),
        "dependabot" => { "status" => "blocked", "policy" => "v1", "evidence" => reason }
      }
    end

    def evidence_status(status, evidence)
      { "status" => status, "evidence" => evidence }
    end

    def evidence_urls(checks)
      checks.filter_map { |check| check["html_url"] }.uniq.join(", ")
    end

    def smoke_name?(value)
      value.to_s.match?(/smoke/i)
    end
  end

  class FleetHealth
    PRODUCT_PACKAGES = {
      "gem" => %w[react_on_rails react_on_rails_pro],
      "npm" => %w[
        react-on-rails react-on-rails-pro react-on-rails-pro-node-renderer create-react-on-rails-app
      ]
    }.freeze
    PUBLIC_REGISTRY_ARTIFACTS = [
      %w[gem react_on_rails],
      %w[gem react_on_rails_pro],
      %w[npm react-on-rails],
      %w[npm react-on-rails-pro],
      %w[npm react-on-rails-pro-node-renderer],
      %w[npm create-react-on-rails-app],
      %w[npm react-on-rails-rsc]
    ].freeze

    attr_reader :targets

    def initialize(manifest:, pack_id:, release:, rsc_version:, policy_commit:, generated_at:)
      @manifest = manifest
      @pack_id = require_nonempty(pack_id, "pack ID")
      @release = require_nonempty(release, "release")
      @rsc_version = require_nonempty(rsc_version, "RSC version")
      @policy_commit = require_commit(policy_commit, "policy commit")
      @generated_at = require_timestamp(generated_at, "generated_at")
      validate_manifest!
      @max_minor_lag = @manifest.dig("standing_health", "max_minor_lag")
      @max_default_age_days = @manifest.dig("standing_health", "max_default_age_days")
      @targets = build_targets
    end

    def evaluate(observations:, registry_artifacts:)
      registry = evaluate_registry(registry_artifacts)
      evaluated_targets = targets.map do |target|
        evaluate_target(target, observations.fetch(target.fetch("id"), {}))
      end
      blocking_targets = evaluated_targets.filter_map do |target|
        target.fetch("id") if target.fetch("status") == "blocked" && target.fetch("disposition") == "active"
      end
      aggregate_findings = []
      aggregate_findings << "registry" unless registry.fetch("status") == "passed"
      aggregate_findings << "active_targets" unless blocking_targets.empty?

      {
        "schema_version" => 1,
        "pack" => {
          "pack_id" => @pack_id,
          "release" => @release,
          "rsc_version" => @rsc_version,
          "policy_commit" => @policy_commit,
          "generated_at" => @generated_at
        },
        "registry" => registry,
        "targets" => evaluated_targets,
        "aggregate" => {
          "status" => aggregate_findings.empty? ? "passed" : "blocked",
          "blocking_targets" => blocking_targets,
          "findings" => aggregate_findings
        }
      }
    end

    def schema
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "title" => "React on Rails public demo fleet standing-health evidence",
        "type" => "object",
        "additionalProperties" => false,
        "required" => %w[schema_version pack registry targets aggregate],
        "properties" => {
          "schema_version" => { "const" => 1 },
          "pack" => object_schema(
            %w[pack_id release rsc_version policy_commit generated_at],
            {
              "pack_id" => nonempty_string,
              "release" => nonempty_string,
              "rsc_version" => nonempty_string,
              "policy_commit" => commit_string,
              "generated_at" => nonempty_string
            }
          ),
          "registry" => object_schema(
            %w[status artifacts findings],
            {
              "status" => { "enum" => %w[passed blocked] },
              "artifacts" => {
                "type" => "array",
                "minItems" => PUBLIC_REGISTRY_ARTIFACTS.length,
                "items" => registry_artifact_schema
              },
              "findings" => string_array
            }
          ),
          "targets" => { "type" => "array", "items" => target_schema },
          "aggregate" => object_schema(
            %w[status blocking_targets findings],
            {
              "status" => { "enum" => %w[passed blocked] },
              "blocking_targets" => string_array,
              "findings" => string_array
            }
          )
        }
      }
    end

    def write_pack(output_dir, evidence)
      errors = SchemaValidator.new(schema).errors(evidence)
      raise ManifestError, "fleet health evidence is invalid: #{errors.join('; ')}" unless errors.empty?

      FileUtils.mkdir_p(output_dir)
      File.write(File.join(output_dir, "fleet-health.json"), "#{JSON.pretty_generate(evidence)}\n")
      File.write(File.join(output_dir, "fleet-health.schema.json"), "#{JSON.pretty_generate(schema)}\n")
      File.write(File.join(output_dir, "fleet-health.md"), render_summary(evidence))
    end

    private

    def validate_manifest!
      raise ManifestError, "schema_version must be 1" unless @manifest["schema_version"] == 1

      standing_health = @manifest["standing_health"]
      raise ManifestError, "standing_health must be a mapping" unless standing_health.is_a?(Hash)
      unless standing_health["schema_version"] == 1
        raise ManifestError, "standing_health.schema_version must be 1"
      end
      unless standing_health["dependabot_policy"] == "v1"
        raise ManifestError, "standing_health.dependabot_policy must be v1"
      end

      %w[max_minor_lag max_default_age_days].each do |field|
        value = standing_health[field]
        unless value.is_a?(Integer) && value >= 0
          raise ManifestError, "standing_health.#{field} must be a nonnegative integer"
        end
      end
      return if @manifest["repos"].is_a?(Array)

      raise ManifestError, "repos must be an array"
    end

    def build_targets
      selected = @manifest.fetch("repos").filter_map do |repo|
        health = repo["standing_health"]
        next unless health.is_a?(Hash) && health["public"] == true

        disposition = health["disposition"]
        unless %w[active report_only archived].include?(disposition)
          raise ManifestError, "#{repo['name']} standing_health.disposition is invalid"
        end
        if repo["tier"] == "soft_track" && disposition == "active"
          raise ManifestError, "#{repo['name']} soft_track cannot be active standing health"
        end

        review_app = health.fetch("review_app", "not_required")
        unless %w[required not_required].include?(review_app)
          raise ManifestError, "#{repo['name']} standing_health.review_app is invalid"
        end

        review_app_workflow = health["review_app_workflow"]
        if review_app == "required" && !exact_workflow_path?(review_app_workflow)
          raise ManifestError,
                "#{repo['name']} standing_health.review_app_workflow must be an exact .github/workflows YAML path"
        end

        {
          "id" => slug(repo.fetch("name")),
          "name" => repo.fetch("name"),
          "tier" => repo.fetch("tier"),
          "disposition" => disposition,
          "review_app" => review_app,
          "review_app_workflow" => review_app_workflow,
          "packages" => Array(repo["packages"]).map { |package| package.slice("ecosystem", "name") }
        }
      end
      archived = Array(@manifest.dig("standing_health", "archived_targets")).map do |repo|
        unless repo.is_a?(Hash) && present?(repo["name"]) && present?(repo["headline"])
          raise ManifestError, "standing_health.archived_targets entries must name a repo and headline"
        end

        {
          "id" => slug(repo.fetch("name")),
          "name" => repo.fetch("name"),
          "tier" => "soft_track",
          "disposition" => "archived",
          "review_app" => "not_required",
          "review_app_workflow" => nil,
          "packages" => Array(repo["packages"]).map { |package| package.slice("ecosystem", "name") }
        }
      end
      selected.concat(archived)
      duplicates = selected.map { |target| target.fetch("id") }.tally.select { |_id, count| count > 1 }.keys
      raise ManifestError, "standing health target IDs collide: #{duplicates.join(', ')}" unless duplicates.empty?
      raise ManifestError, "standing health has no public targets" if selected.empty?

      selected
    end

    def exact_workflow_path?(value)
      value.is_a?(String) && value.match?(%r{\A\.github/workflows/[A-Za-z0-9][A-Za-z0-9._-]*\.ya?ml\z})
    end

    def evaluate_registry(artifacts)
      indexed = Array(artifacts).to_h do |artifact|
        [[artifact["ecosystem"], artifact["name"]], artifact]
      end
      findings = PUBLIC_REGISTRY_ARTIFACTS.filter_map do |ecosystem, name|
        artifact = indexed[[ecosystem, name]]
        expected = name == "react-on-rails-rsc" ? @rsc_version : normalized_release(ecosystem)
        "#{ecosystem}:#{name}" unless artifact && artifact["version"] == expected && present?(artifact["source"])
      end

      {
        "status" => findings.empty? ? "passed" : "blocked",
        "artifacts" => Array(artifacts),
        "findings" => findings
      }
    end

    def evaluate_target(target, observation)
      findings = []
      currency = evaluate_currency(target, observation)
      findings << "currency" unless currency.fetch("status") == "passed"

      default_ci = normalize_evidence_status(observation["default_ci"])
      smoke = normalize_smoke_status(observation["smoke"])
      review_app = normalize_evidence_status(observation["review_app"])
      dependabot = normalize_dependabot_status(observation["dependabot"])
      staleness = evaluate_staleness(observation["default_commit_at"])

      if target.fetch("disposition") == "active"
        findings << "default_ci" unless default_ci.fetch("status") == "passed"
        findings << "smoke" unless smoke.fetch("status") == "passed" && smoke.fetch("shared_contract")
        if target.fetch("review_app") == "required" && review_app.fetch("status") != "passed"
          findings << "review_app"
        end
        findings << "dependabot" unless dependabot.fetch("status") == "passed"
        findings << "staleness" unless staleness.fetch("status") == "passed"
      end

      {
        "id" => target.fetch("id"),
        "name" => target.fetch("name"),
        "tier" => target.fetch("tier"),
        "disposition" => target.fetch("disposition"),
        "default_branch" => nullable_string_value(observation["default_branch"]),
        "default_commit" => nullable_string_value(observation["default_commit"]),
        "default_commit_at" => nullable_string_value(observation["default_commit_at"]),
        "observed_at" => nullable_string_value(observation["observed_at"]),
        "currency" => currency,
        "default_ci" => default_ci,
        "smoke" => smoke,
        "review_app" => review_app,
        "dependabot" => dependabot,
        "staleness" => staleness,
        "status" => if target.fetch("disposition") == "active"
                      findings.empty? ? "passed" : "blocked"
                    else
                      "reported"
                    end,
        "findings" => findings
      }
    end

    def evaluate_currency(target, observation)
      expected_packages = target.fetch("packages").filter_map do |package|
        expected = expected_version(package["ecosystem"], package["name"])
        package.merge("expected" => expected) if expected
      end
      expected_keys = expected_packages.map { |package| [package["ecosystem"], package["name"]] }
      observed = Array(observation["package_versions"]).select do |package|
        expected_keys.include?([package["ecosystem"], package["name"]])
      end
      findings = expected_packages.filter_map do |package|
        key = [package["ecosystem"], package["name"]]
        actual_versions = observed.filter_map do |actual|
          actual["version"] if key == [actual["ecosystem"], actual["name"]]
        end
        all_acceptable = actual_versions.any? && actual_versions.all? do |actual|
          acceptable_version?(package["ecosystem"], package["name"], actual, package["expected"])
        end
        package["name"] unless all_acceptable
      end

      {
        "status" => findings.empty? ? "passed" : "blocked",
        "expected" => expected_packages,
        "observed" => observed,
        "findings" => findings
      }
    end

    def expected_version(ecosystem, name)
      if name == "react-on-rails-rsc"
        @rsc_version
      elsif PRODUCT_PACKAGES.fetch(ecosystem, []).include?(name)
        normalized_release(ecosystem)
      end
    end

    def acceptable_version?(_ecosystem, name, actual, expected)
      return actual == expected if name == "react-on-rails-rsc"

      actual_version = Gem::Version.new(actual)
      expected_version = Gem::Version.new(expected)
      return false if actual_version.prerelease? || expected_version.prerelease?

      actual_segments = actual_version.segments
      expected_segments = expected_version.segments
      same_major = actual_segments.fetch(0, 0) == expected_segments.fetch(0, 0)
      minor_lag = expected_segments.fetch(1, 0) - actual_segments.fetch(1, 0)
      same_major && minor_lag.between?(0, @max_minor_lag)
    rescue ArgumentError
      false
    end

    def normalized_release(ecosystem)
      version = @release.delete_prefix("v")
      ecosystem == "npm" ? version.gsub(/\.((?:rc|beta))\.(\d+)\z/, '-\\1.\\2') : version
    end

    def normalize_evidence_status(value)
      value = {} unless value.is_a?(Hash)
      status = value["status"]
      status = "unknown" unless %w[passed blocked unknown not_applicable].include?(status)
      {
        "status" => status,
        "evidence" => nullable_string_value(value["evidence"])
      }
    end

    def normalize_smoke_status(value)
      normalized = normalize_evidence_status(value)
      normalized["shared_contract"] = value.is_a?(Hash) && value["shared_contract"] == true
      normalized
    end

    def normalize_dependabot_status(value)
      normalized = normalize_evidence_status(value)
      normalized["policy"] = value.is_a?(Hash) && value["policy"] == "v1" ? "v1" : "unknown"
      normalized
    end

    def evaluate_staleness(default_commit_at)
      commit_time = Time.iso8601(default_commit_at.to_s)
      age_days = ((Time.iso8601(@generated_at) - commit_time) / 86_400).floor
      {
        "status" => age_days <= @max_default_age_days ? "passed" : "blocked",
        "age_days" => age_days,
        "max_age_days" => @max_default_age_days,
        "evidence" => default_commit_at
      }
    rescue ArgumentError
      {
        "status" => "unknown",
        "age_days" => nil,
        "max_age_days" => @max_default_age_days,
        "evidence" => nullable_string_value(default_commit_at)
      }
    end

    def render_summary(evidence)
      rows = evidence.fetch("targets").map do |target|
        findings = target.fetch("findings")
        "| `#{escape(target.fetch('id'))}` | #{target.fetch('disposition')} | #{target.fetch('status')} | " \
          "#{findings.empty? ? 'none' : findings.join(', ')} |"
      end
      <<~MARKDOWN
        # Public demo fleet standing health

        Pack: `#{escape(evidence.dig('pack', 'pack_id'))}`
        Release: `#{escape(evidence.dig('pack', 'release'))}`
        RSC: `#{escape(evidence.dig('pack', 'rsc_version'))}`
        Aggregate: **#{escape(evidence.dig('aggregate', 'status').upcase)}**

        | Target | Disposition | Status | Findings |
        | --- | --- | --- | --- |
        #{rows.join("\n")}
      MARKDOWN
    end

    def target_schema
      object_schema(
        %w[
          id name tier disposition default_branch default_commit default_commit_at observed_at currency default_ci smoke
          review_app dependabot staleness status findings
        ],
        {
          "id" => nonempty_string,
          "name" => nonempty_string,
          "tier" => { "enum" => %w[hard_gate soft_track] },
          "disposition" => { "enum" => %w[active report_only archived] },
          "default_branch" => nullable_string,
          "default_commit" => nullable_string,
          "default_commit_at" => nullable_string,
          "observed_at" => nullable_string,
          "currency" => currency_schema,
          "default_ci" => evidence_status_schema,
          "smoke" => smoke_status_schema,
          "review_app" => evidence_status_schema,
          "dependabot" => dependabot_status_schema,
          "staleness" => staleness_schema,
          "status" => { "enum" => %w[passed blocked reported] },
          "findings" => string_array
        }
      )
    end

    def currency_schema
      object_schema(
        %w[status expected observed findings],
        {
          "status" => { "enum" => %w[passed blocked] },
          "expected" => {
            "type" => "array",
            "items" => object_schema(
              %w[ecosystem name expected],
              {
                "ecosystem" => { "enum" => %w[gem npm] },
                "name" => nonempty_string,
                "expected" => nonempty_string
              }
            )
          },
          "observed" => { "type" => "array", "items" => package_version_schema },
          "findings" => string_array
        }
      )
    end

    def registry_artifact_schema
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

    def package_version_schema
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

    def evidence_status_schema
      object_schema(
        %w[status evidence],
        {
          "status" => { "enum" => %w[passed blocked unknown not_applicable] },
          "evidence" => nullable_string
        }
      )
    end

    def smoke_status_schema
      object_schema(
        %w[status evidence shared_contract],
        evidence_status_schema.fetch("properties").merge("shared_contract" => { "type" => "boolean" })
      )
    end

    def dependabot_status_schema
      object_schema(
        %w[status evidence policy],
        evidence_status_schema.fetch("properties").merge("policy" => { "enum" => %w[v1 unknown] })
      )
    end

    def staleness_schema
      object_schema(
        %w[status age_days max_age_days evidence],
        {
          "status" => { "enum" => %w[passed blocked unknown] },
          "age_days" => { "type" => %w[integer null] },
          "max_age_days" => { "type" => "integer" },
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

    def nonempty_string
      { "type" => "string", "minLength" => 1 }
    end

    def commit_string
      { "type" => "string", "pattern" => "\\A[0-9a-f]{40}\\z" }
    end

    def nullable_string
      { "type" => %w[string null] }
    end

    def string_array
      { "type" => "array", "items" => nonempty_string }
    end

    def nullable_string_value(value)
      present?(value) ? value : nil
    end

    def present?(value)
      !value.nil? && (!value.respond_to?(:empty?) || !value.empty?)
    end

    def require_nonempty(value, label)
      raise ManifestError, "#{label} must be nonempty" unless present?(value)

      value
    end

    def require_commit(value, label)
      raise ManifestError, "#{label} must be a 40-character commit" unless value.to_s.match?(/\A[0-9a-f]{40}\z/)

      value
    end

    def require_timestamp(value, label)
      Time.iso8601(value)
      value
    rescue ArgumentError
      raise ManifestError, "#{label} must be an ISO-8601 timestamp"
    end

    def slug(value)
      value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end

    def escape(value)
      value.to_s.gsub("|", "\\|").gsub("<!--", "&lt;!--").gsub("-->", "--&gt;")
    end
  end
end
