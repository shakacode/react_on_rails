#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"
require_relative "fleet_health"
require_relative "check_fleet_health"

class FleetHealthTest < Minitest::Test
  FIXTURE = File.expand_path("../fixtures/rc12-health-drift.yml", __dir__)
  RC12_REPLAY = File.expand_path("replay_rc12_fleet_health.rb", __dir__)
  CHECK_FLEET_HEALTH = File.expand_path("check_fleet_health.rb", __dir__)
  REUSABLE_SMOKE = File.expand_path("../../../../.github/workflows/demo-fleet-smoke.yml", __dir__)
  SCHEDULED_HEALTH = File.expand_path("../../../../.github/workflows/demo-fleet-health.yml", __dir__)
  SKILL = File.expand_path("../SKILL.md", __dir__)
  RC_PLAN = File.expand_path("../../../../internal/contributor-info/rc-testing-plan.md", __dir__)
  RELEASE_RUNBOOK = File.expand_path("../../../../internal/contributor-info/release-verification-runbook.md", __dir__)
  MANIFEST = File.expand_path("../../../../internal/contributor-info/demo-fleet.yml", __dir__)
  RUBY_SETUP_SHA = "9eb537ca036ebaed86729dcb9309076e4c5c3b74"

  def setup
    fixture = YAML.safe_load_file(FIXTURE, aliases: false)
    @manifest = fixture.fetch("manifest")
    @observations = fixture.fetch("observations")
    @contract = FleetValidation::FleetHealth.new(
      manifest: @manifest,
      pack_id: "stable-public-17-0-0",
      release: "v17.0.0",
      rsc_version: "19.2.1",
      policy_commit: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
      generated_at: "2026-07-18T12:00:00Z"
    )
  end

  def test_selects_only_explicit_public_health_targets
    assert_equal(
      %w[
        sanitized-active-current
        sanitized-active-drifted
        sanitized-report-only
        sanitized-archived
      ],
      @contract.targets.map { |target| target.fetch("id") }
    )
  end

  def test_required_review_app_requires_an_exact_workflow_path
    manifest = Marshal.load(Marshal.dump(@manifest))
    manifest.fetch("repos").first.fetch("standing_health")["review_app_workflow"] = " "

    error = assert_raises(FleetValidation::ManifestError) do
      FleetValidation::FleetHealth.new(
        manifest:,
        pack_id: "missing-review-app-path",
        release: "v17.0.0",
        rsc_version: "19.2.1",
        policy_commit: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        generated_at: "2026-07-18T12:00:00Z"
      )
    end

    assert_includes error.message, "review_app_workflow"
  end

  def test_manifest_rejects_unknown_package_ecosystems_and_names
    unknown_name = Marshal.load(Marshal.dump(@manifest))
    unknown_name.fetch("repos").first.fetch("packages") << {
      "ecosystem" => "npm",
      "name" => "react-on-rail"
    }
    error = assert_raises(FleetValidation::ManifestError) { build_contract(unknown_name) }
    assert_includes error.message, "react-on-rail"

    unknown_ecosystem = Marshal.load(Marshal.dump(@manifest))
    unknown_ecosystem.fetch("repos").first.fetch("packages") << {
      "ecosystem" => "cargo",
      "name" => "react-on-rails"
    }
    error = assert_raises(FleetValidation::ManifestError) { build_contract(unknown_ecosystem) }
    assert_includes error.message, "cargo"
  end

  def test_manifest_allows_intentional_non_product_packages
    manifest = Marshal.load(Marshal.dump(@manifest))
    packages = [
      { "ecosystem" => "gem", "name" => "shakapacker" },
      { "ecosystem" => "gem", "name" => "cpflow" },
      { "ecosystem" => "npm", "name" => "shakapacker" },
      { "ecosystem" => "npm", "name" => "shakapacker-rspack" }
    ]
    manifest.fetch("repos").first.fetch("packages").concat(packages)

    contract = build_contract(manifest)

    assert_includes contract.targets.first.fetch("packages"), { "ecosystem" => "gem", "name" => "cpflow" }
    assert_includes contract.targets.first.fetch("packages"), {
      "ecosystem" => "npm",
      "name" => "shakapacker-rspack"
    }
  end

  def test_active_drift_blocks_aggregate_while_soft_and_archived_targets_are_report_only
    evidence = @contract.evaluate(
      observations: @observations,
      registry_artifacts: stable_registry_artifacts
    )

    current = target(evidence, "sanitized-active-current")
    drifted = target(evidence, "sanitized-active-drifted")
    report_only = target(evidence, "sanitized-report-only")
    archived = target(evidence, "sanitized-archived")

    assert_equal "passed", current.fetch("status")
    assert_equal "blocked", drifted.fetch("status")
    assert_includes drifted.fetch("findings"), "currency"
    assert_includes drifted.fetch("findings"), "default_ci"
    assert_includes drifted.fetch("findings"), "smoke"
    assert_includes drifted.fetch("findings"), "review_app"
    assert_includes drifted.fetch("findings"), "dependabot"
    assert_includes drifted.fetch("findings"), "staleness"
    assert_equal "passed", current.dig("staleness", "status")
    assert_equal "blocked", drifted.dig("staleness", "status")
    assert_equal "reported", report_only.fetch("status")
    assert_equal "reported", archived.fetch("status")
    assert_equal %w[currency default_ci smoke dependabot staleness], report_only.fetch("findings")
    assert_equal %w[default_ci smoke dependabot staleness], archived.fetch("findings")
    assert_equal "blocked", evidence.dig("aggregate", "status")
    assert_equal ["sanitized-active-drifted"], evidence.dig("aggregate", "blocking_targets")
  end

  def test_future_default_commit_timestamp_is_unknown_instead_of_fresh
    observations = Marshal.load(Marshal.dump(@observations))
    observations.fetch("sanitized-active-current")["default_commit_at"] = "2026-07-19T12:00:00Z"

    evidence = @contract.evaluate(
      observations:,
      registry_artifacts: stable_registry_artifacts
    )
    current = target(evidence, "sanitized-active-current")

    assert_equal "unknown", current.dig("staleness", "status")
    assert_equal(-1, current.dig("staleness", "age_days"))
    assert_includes current.dig("staleness", "evidence"), "future default commit timestamp"
    assert_includes current.fetch("findings"), "staleness"
    assert_equal "blocked", current.fetch("status")
  end

  def test_report_only_target_retains_required_review_app_drift_without_blocking
    manifest = Marshal.load(Marshal.dump(@manifest))
    report_only = manifest.fetch("repos").find { |repo| repo["name"] == "sanitized/report-only" }
    report_only.fetch("standing_health").merge!(
      "review_app" => "required",
      "review_app_workflow" => ".github/workflows/cpflow-deploy-review-app.yml"
    )
    contract = build_contract(manifest)

    evidence = contract.evaluate(observations: @observations, registry_artifacts: stable_registry_artifacts)
    target = target(evidence, "sanitized-report-only")

    assert_equal "reported", target.fetch("status")
    assert_includes target.fetch("findings"), "review_app"
    refute_includes evidence.dig("aggregate", "blocking_targets"), "sanitized-report-only"
  end

  def test_active_repository_archival_is_surfaced_as_blocking_manifest_drift
    observations = Marshal.load(Marshal.dump(@observations))
    observations.fetch("sanitized-active-current")["repository_archived"] = true

    evidence = @contract.evaluate(
      observations:,
      registry_artifacts: stable_registry_artifacts
    )
    current = target(evidence, "sanitized-active-current")

    assert_equal true, current.fetch("repository_archived")
    assert_includes current.fetch("findings"), "repository_archived"
    assert_equal "blocked", current.fetch("status")
  end

  def test_registry_artifacts_must_be_exact_stable_public_versions
    artifacts = stable_registry_artifacts
    artifacts[0]["version"] = "17.0.0.rc.12"

    evidence = @contract.evaluate(observations: @observations, registry_artifacts: artifacts)

    assert_equal "blocked", evidence.dig("registry", "status")
    assert_includes evidence.dig("aggregate", "findings"), "registry"
  end

  def test_product_currency_allows_at_most_one_minor_of_stable_lag
    contract = FleetValidation::FleetHealth.new(
      manifest: @manifest,
      pack_id: "minor-lag",
      release: "v17.1.0",
      rsc_version: "19.2.1",
      policy_commit: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
      generated_at: "2026-07-18T12:00:00Z"
    )
    observations = Marshal.load(Marshal.dump(@observations))
    current = observations.fetch("sanitized-active-current")
    current.fetch("package_versions").each do |package|
      package["version"] = "17.0.5" unless package["name"] == "react-on-rails-rsc"
    end
    evidence = contract.evaluate(
      observations:,
      registry_artifacts: [
        { "ecosystem" => "gem", "name" => "react_on_rails", "version" => "17.1.0", "source" => "registry" },
        { "ecosystem" => "npm", "name" => "react-on-rails", "version" => "17.1.0", "source" => "registry" },
        { "ecosystem" => "npm", "name" => "react-on-rails-rsc", "version" => "19.2.1", "source" => "registry" }
      ]
    )

    assert_equal "passed", target(evidence, "sanitized-active-current").dig("currency", "status")
  end

  def test_currency_rejects_mixed_direct_versions_and_keeps_only_relevant_packages
    observations = Marshal.load(Marshal.dump(@observations))
    current = observations.fetch("sanitized-active-current")
    current.fetch("package_versions").prepend(
      {
        "ecosystem" => "gem",
        "name" => "unrelated",
        "version" => "1.0.0",
        "source" => "github-sbom"
      },
      {
        "ecosystem" => "gem",
        "name" => "react_on_rails",
        "version" => "16.0.0",
        "source" => "github-sbom"
      }
    )

    evidence = @contract.evaluate(
      observations:,
      registry_artifacts: stable_registry_artifacts
    )
    currency = target(evidence, "sanitized-active-current").fetch("currency")

    assert_equal "blocked", currency.fetch("status")
    assert_includes currency.fetch("findings"), "react_on_rails"
    refute_includes currency.fetch("observed").map { |package| package.fetch("name") }, "unrelated"
  end

  def test_schema_rejects_unknown_fields
    evidence = @contract.evaluate(
      observations: @observations,
      registry_artifacts: stable_registry_artifacts
    )
    evidence["unexpected"] = true

    errors = FleetValidation::SchemaValidator.new(@contract.schema).errors(evidence)

    assert(errors.any? { |error| error.include?("unexpected") })
  end

  def test_schema_uses_an_ecma_262_commit_pattern
    pattern = @contract.schema.dig("properties", "pack", "properties", "policy_commit", "pattern")

    assert_equal "^[0-9a-f]{40}$", pattern
    assert_match Regexp.new(pattern), "7d787fcc1e3fbcfd655bc8bc79401e3a657d9550"
  end

  def test_markdown_escaping_preserves_literal_backslashes_and_table_delimiters
    escaped = @contract.send(:escape, "literal\\path|column`code\nnext")

    assert_equal 4, escaped.count("\\")
    assert_includes escaped, '\|'
    assert_includes escaped, '\`'
    refute_includes escaped, "\n"
  end

  def test_writes_a_machine_readable_pack_and_human_summary
    evidence = @contract.evaluate(
      observations: @observations,
      registry_artifacts: stable_registry_artifacts
    )

    Dir.mktmpdir do |directory|
      @contract.write_pack(directory, evidence)

      assert File.exist?(File.join(directory, "fleet-health.json"))
      assert File.exist?(File.join(directory, "fleet-health.schema.json"))
      assert_includes File.read(File.join(directory, "fleet-health.md")), "sanitized-active-drifted"
    end
  end

  def test_sanitized_rc12_replay_detects_standing_health_drift
    stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", RC12_REPLAY)

    assert status.success?, stderr
    assert_includes stdout, "SANITIZED_RC12_FLEET_HEALTH_REPLAY_PASS"
    assert_includes stdout, "blocking_targets=1"
    assert_includes stdout, "report_only_targets=2"
  end

  def test_cli_writes_an_offline_evidence_pack
    Dir.mktmpdir do |directory|
      manifest_path = File.join(directory, "manifest.yml")
      observations_path = File.join(directory, "observations.yml")
      registry_path = File.join(directory, "registry.yml")
      output_dir = File.join(directory, "pack")
      File.write(manifest_path, YAML.dump(@manifest))
      File.write(observations_path, YAML.dump(@observations))
      File.write(registry_path, YAML.dump(stable_registry_artifacts))

      _stdout, stderr, status = Open3.capture3(
        "bundle", "exec", "ruby", CHECK_FLEET_HEALTH,
        "--manifest", manifest_path,
        "--observations", observations_path,
        "--registry-artifacts", registry_path,
        "--pack-id", "offline-test",
        "--policy-commit", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "--generated-at", "2026-07-18T12:00:00Z",
        "--output-dir", output_dir
      )

      assert status.success?, stderr
      evidence = JSON.parse(File.read(File.join(output_dir, "fleet-health.json")))
      assert_equal "v17.0.0", evidence.dig("pack", "release")
      assert_equal "19.2.1", evidence.dig("pack", "rsc_version")
    end
  end

  def test_live_cli_reports_transient_network_errors_without_a_backtrace
    Dir.mktmpdir do |directory|
      manifest = Marshal.load(Marshal.dump(@manifest))
      manifest.fetch("standing_health").merge!(
        "stable_release" => "v17.0.0",
        "rsc_version" => "19.2.1"
      )
      manifest_path = File.join(directory, "manifest.yml")
      File.write(manifest_path, YAML.dump(manifest))
      client = Object.new
      client.define_singleton_method(:json) do |_url|
        raise FleetValidation::TransientPublicRequestError, "SocketError: temporary DNS failure"
      end
      result = nil
      arguments = [
        "--manifest", manifest_path,
        "--live",
        "--policy-commit", "e" * 40,
        "--output-dir", File.join(directory, "pack")
      ]

      _stdout, stderr = capture_io do
        result = FleetValidation::FleetHealthCLI.run(arguments, http: client)
      end

      assert_equal 1, result
      assert_match(/\AERROR: live public request failed: SocketError: temporary DNS failure\n\z/, stderr)
      refute_includes stderr, CHECK_FLEET_HEALTH
    end
  end

  def test_public_http_client_wraps_only_transient_transport_errors
    transport = Object.new
    transport.define_singleton_method(:start) { |*_args, **_kwargs| raise SocketError, "temporary DNS failure" }
    client = FleetValidation::PublicHTTPClient.new(github_token: nil, transport:)

    error = assert_raises(FleetValidation::TransientPublicRequestError) do
      client.json("https://registry.npmjs.org/react-on-rails")
    end

    assert_equal "SocketError: temporary DNS failure", error.message
  end

  def test_public_github_client_translates_only_missing_content_responses
    status = 404
    http = Object.new
    http.define_singleton_method(:json) do |_url|
      raise FleetValidation::PublicHTTPResponseError.new(status, "request failed")
    end
    client = FleetValidation::PublicGitHubClient.new(http:)

    assert_raises(FleetValidation::MissingPublicContentError) do
      client.content("sanitized/demo", ".github/dependabot.yml", ref: "a" * 40)
    end

    status = 500
    error = assert_raises(FleetValidation::PublicHTTPResponseError) do
      client.content("sanitized/demo", ".github/dependabot.yml", ref: "a" * 40)
    end
    assert_equal 500, error.status
  end

  def test_cli_explicit_versions_override_manifest_defaults
    options = { release: "v18.0.0", rsc_version: "20.0.0" }

    FleetValidation::FleetHealthCLI.apply_manifest_versions!(options, @manifest)

    assert_equal "v18.0.0", options.fetch(:release)
    assert_equal "20.0.0", options.fetch(:rsc_version)
  end

  def test_dependabot_v1_requires_enabled_weekly_coverage_for_each_ecosystem
    config = {
      "version" => 2,
      "updates" => [
        {
          "package-ecosystem" => "bundler",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" },
          "groups" => { "react-on-rails" => { "patterns" => ["react_on_rails*"] } }
        },
        {
          "package-ecosystem" => "npm",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" },
          "groups" => { "react-on-rails" => { "patterns" => ["react-on-rails*"] } }
        },
        {
          "package-ecosystem" => "github-actions",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" }
        }
      ]
    }
    packages = [
      { "ecosystem" => "gem", "name" => "react_on_rails" },
      { "ecosystem" => "npm", "name" => "react-on-rails" }
    ]

    passed = FleetValidation::DependabotV1.evaluate(config, packages)
    config.fetch("updates")[1]["open-pull-requests-limit"] = 0
    blocked = FleetValidation::DependabotV1.evaluate(config, packages)

    assert_equal "passed", passed.fetch("status")
    assert_equal "blocked", blocked.fetch("status")
    assert_includes blocked.fetch("findings"), "npm:version-updates-disabled"
  end

  def test_dependabot_v1_requires_one_enabled_weekly_root_entry
    config = dependabot_v1_config
    npm = config.fetch("updates").find { |entry| entry["package-ecosystem"] == "npm" }
    npm["open-pull-requests-limit"] = 0
    config.fetch("updates") << npm.merge(
      "schedule" => { "interval" => "daily" },
      "open-pull-requests-limit" => 5
    )

    result = FleetValidation::DependabotV1.evaluate(
      config,
      [{ "ecosystem" => "npm", "name" => "react-on-rails" }]
    )

    assert_equal "blocked", result.fetch("status")
    assert_includes result.fetch("findings"), "npm:not-weekly"
  end

  def test_dependabot_v1_rejects_weekly_coverage_outside_the_root
    config = dependabot_v1_config
    npm = config.fetch("updates").find { |entry| entry["package-ecosystem"] == "npm" }
    npm["directory"] = "/docs"
    config.fetch("updates") << npm.merge(
      "directory" => "/",
      "schedule" => { "interval" => "daily" }
    )

    result = FleetValidation::DependabotV1.evaluate(
      config,
      [{ "ecosystem" => "npm", "name" => "react-on-rails" }]
    )

    assert_equal "blocked", result.fetch("status")
    assert_includes result.fetch("findings"), "npm:not-weekly"
  end

  def test_dependabot_v1_requires_product_grouping_on_an_enabled_weekly_root_entry
    config = dependabot_v1_config
    npm = config.fetch("updates").find { |entry| entry["package-ecosystem"] == "npm" }
    npm["open-pull-requests-limit"] = 0
    config.fetch("updates") << npm.merge(
      "groups" => {},
      "open-pull-requests-limit" => 5
    )

    result = FleetValidation::DependabotV1.evaluate(
      config,
      [{ "ecosystem" => "npm", "name" => "react-on-rails" }]
    )

    assert_equal "blocked", result.fetch("status")
    assert_includes result.fetch("findings"), "npm:product-group-missing"
  end

  def test_dependabot_status_falls_back_to_the_supported_yaml_path
    repo = "sanitized/demo"
    head = "a" * 40
    requests = []
    config = dependabot_v1_config
    client = Object.new
    client.define_singleton_method(:content) do |_repo, path, ref:|
      requests << [path, ref]
      raise FleetValidation::MissingPublicContentError, "missing" if path == ".github/dependabot.yml"

      YAML.dump(config)
    end
    probe = public_github_probe(client:)

    result = probe.send(:dependabot_status, repo, head, @contract.targets.first.fetch("packages"))

    assert_equal "passed", result.fetch("status")
    assert_equal ".github/dependabot.yaml", result.fetch("evidence")
    assert_equal(
      [
        [".github/dependabot.yml", head],
        [".github/dependabot.yaml", head]
      ],
      requests
    )
  end

  def test_dependabot_status_fails_closed_when_both_supported_paths_are_unavailable
    repo = "sanitized/demo"
    head = "a" * 40
    requests = []
    client = Object.new
    client.define_singleton_method(:content) do |_repo, path, ref:|
      requests << [path, ref]
      raise FleetValidation::MissingPublicContentError, "missing"
    end
    probe = public_github_probe(client:)

    result = probe.send(:dependabot_status, repo, head, @contract.targets.first.fetch("packages"))

    assert_equal "blocked", result.fetch("status")
    assert_includes result.fetch("evidence"), "MissingPublicContentError"
    assert_equal(
      [
        [".github/dependabot.yml", head],
        [".github/dependabot.yaml", head]
      ],
      requests
    )
  end

  def test_public_sbom_parser_extracts_gem_and_npm_versions
    sbom = {
      "sbom" => {
        "SPDXID" => "SPDXRef-DOCUMENT",
        "packages" => [
          { "SPDXID" => "SPDXRef-Root", "name" => "demo" },
          {
            "SPDXID" => "SPDXRef-Gem",
            "externalRefs" => [{ "referenceType" => "purl", "referenceLocator" => "pkg:gem/react_on_rails@17.0.0" }]
          },
          {
            "SPDXID" => "SPDXRef-Npm",
            "externalRefs" => [{ "referenceType" => "purl", "referenceLocator" => "pkg:npm/react-on-rails@17.0.0" }]
          },
          {
            "SPDXID" => "SPDXRef-Transitive",
            "externalRefs" => [{ "referenceType" => "purl", "referenceLocator" => "pkg:npm/react-on-rails@16.0.0" }]
          }
        ],
        "relationships" => [
          {
            "spdxElementId" => "SPDXRef-DOCUMENT",
            "relationshipType" => "DESCRIBES",
            "relatedSpdxElement" => "SPDXRef-Root"
          },
          {
            "spdxElementId" => "SPDXRef-Root",
            "relationshipType" => "DEPENDS_ON",
            "relatedSpdxElement" => "SPDXRef-Gem"
          },
          {
            "spdxElementId" => "SPDXRef-Root",
            "relationshipType" => "DEPENDS_ON",
            "relatedSpdxElement" => "SPDXRef-Npm"
          },
          {
            "spdxElementId" => "SPDXRef-Npm",
            "relationshipType" => "DEPENDS_ON",
            "relatedSpdxElement" => "SPDXRef-Transitive"
          }
        ]
      }
    }

    versions = FleetValidation::PublicSBOM.package_versions(sbom)

    assert_equal(
      [
        { "ecosystem" => "gem", "name" => "react_on_rails", "version" => "17.0.0", "source" => "github-sbom" },
        { "ecosystem" => "npm", "name" => "react-on-rails", "version" => "17.0.0", "source" => "github-sbom" }
      ],
      versions
    )
  end

  def test_public_sbom_parser_fails_closed_without_a_root_dependency_identity
    sbom = {
      "sbom" => {
        "SPDXID" => "SPDXRef-DOCUMENT",
        "packages" => [
          {
            "SPDXID" => "SPDXRef-Gem",
            "externalRefs" => [{ "referenceType" => "purl", "referenceLocator" => "pkg:gem/react_on_rails@17.0.0" }]
          }
        ],
        "relationships" => []
      }
    }

    assert_empty FleetValidation::PublicSBOM.package_versions(sbom)
  end

  def test_public_registry_resolver_verifies_exact_stable_artifacts
    responses = {
      "https://rubygems.org/api/v1/versions/react_on_rails.json" => [
        { "number" => "17.0.0", "yanked" => false }
      ],
      "https://rubygems.org/api/v1/versions/react_on_rails_pro.json" => [
        { "number" => "17.0.0", "yanked" => false }
      ],
      "https://registry.npmjs.org/react-on-rails" => { "versions" => { "17.0.0" => {} } },
      "https://registry.npmjs.org/react-on-rails-pro" => { "versions" => { "17.0.0" => {} } },
      "https://registry.npmjs.org/react-on-rails-pro-node-renderer" => { "versions" => { "17.0.0" => {} } },
      "https://registry.npmjs.org/create-react-on-rails-app" => { "versions" => { "17.0.0" => {} } },
      "https://registry.npmjs.org/react-on-rails-rsc" => {
        "versions" => { "19.2.1" => {} }
      }
    }
    resolver = FleetValidation::PublicRegistryResolver.new(fetcher: ->(url) { responses.fetch(url) })

    artifacts = resolver.resolve(release: "v17.0.0", rsc_version: "19.2.1")

    assert_equal stable_registry_artifacts, artifacts
    assert_equal 7, @contract.schema.dig("properties", "registry", "properties", "artifacts", "minItems")
  end

  def test_public_registry_resolver_normalizes_npm_prerelease_versions
    resolver = FleetValidation::PublicRegistryResolver.new(fetcher: lambda do |url|
      if URI(url).host == "rubygems.org"
        [{ "number" => "17.0.0.rc.12", "yanked" => false }]
      else
        { "versions" => { "17.0.0-rc.12" => {}, "19.2.1" => {} } }
      end
    end)

    artifacts = resolver.resolve(release: "v17.0.0.rc.12", rsc_version: "19.2.1")

    assert_equal(
      Array.new(4, "17.0.0-rc.12"),
      artifacts.select { |artifact| artifact["ecosystem"] == "npm" && artifact["name"] != "react-on-rails-rsc" }
               .map { |artifact| artifact.fetch("version") }
    )
    assert_equal(
      Array.new(2, "17.0.0.rc.12"),
      artifacts.select { |artifact| artifact["ecosystem"] == "gem" }.map { |artifact| artifact.fetch("version") }
    )
  end

  def test_public_registry_resolver_rejects_an_incomplete_product_suite
    resolver = FleetValidation::PublicRegistryResolver.new(fetcher: lambda do |url|
      next [] if url.end_with?("react_on_rails_pro.json")

      if URI(url).host == "rubygems.org"
        [{ "number" => "17.0.0", "yanked" => false }]
      else
        { "versions" => { "17.0.0" => {}, "19.2.1" => {} } }
      end
    end)

    error = assert_raises(FleetValidation::ManifestError) do
      resolver.resolve(release: "v17.0.0", rsc_version: "19.2.1")
    end
    assert_includes error.message, "react_on_rails_pro"
  end

  def test_public_github_probe_stops_after_non_public_metadata
    target = @contract.targets.first
    requests = []
    client = Object.new
    client.define_singleton_method(:get) do |path|
      requests << path
      raise "non-metadata read attempted" unless requests.one?

      { "visibility" => "private-secret", "default_branch" => "main" }
    end
    probe = public_github_probe(client:)

    error = assert_raises(FleetValidation::NonPublicRepositoryError) do
      probe.observe(target, observed_at: "2026-07-18T12:00:00Z")
    end

    assert_equal ["/repos/#{target.fetch('name')}"], requests
    refute_includes error.message, "private-secret"
  end

  def test_default_ci_requires_a_successful_exact_head_check
    probe = public_github_probe(client: nil)
    skipped = {
      "name" => "Paths filtered",
      "status" => "completed",
      "conclusion" => "skipped",
      "html_url" => "https://example.invalid/skipped"
    }
    success = skipped.merge(
      "name" => "CI",
      "conclusion" => "success",
      "html_url" => "https://example.invalid/success"
    )
    pending = success.merge("status" => "in_progress", "conclusion" => nil)

    assert_equal "unknown", probe.send(:check_status, [skipped]).fetch("status")
    assert_equal "passed", probe.send(:check_status, [skipped, success]).fetch("status")
    assert_equal "unknown", probe.send(:check_status, [success, pending]).fetch("status")
  end

  def test_default_ci_includes_check_runs_after_the_first_page
    path = "/repos/sanitized/demo/commits/#{'a' * 40}/check-runs?per_page=100"
    success = {
      "status" => "completed",
      "conclusion" => "success",
      "html_url" => "https://example.invalid/success"
    }
    failure = {
      "status" => "completed",
      "conclusion" => "failure",
      "html_url" => "https://example.invalid/failure"
    }
    client = Struct.new(:first_path, :success, :failure) do
      def get(path)
        return { "check_runs" => Array.new(100) { success.dup } } if path == first_path
        return { "check_runs" => [failure] } if path == "#{first_path}&page=2"

        raise "unexpected page #{path}"
      end
    end.new(path, success, failure)
    probe = public_github_probe(client:)

    checks = probe.send(:paginated_collection, path, "check_runs")

    assert_equal 101, checks.length
    assert_equal "blocked", probe.send(:check_status, checks).fetch("status")
  end

  def test_check_run_pagination_fails_closed_at_the_bound
    path = "/repos/sanitized/demo/commits/#{'a' * 40}/check-runs?per_page=100"
    client = Struct.new(:requests) do
      def get(path)
        requests << path
        { "check_runs" => Array.new(100) { { "status" => "completed", "conclusion" => "success" } } }
      end
    end.new([])
    probe = public_github_probe(client:)

    error = assert_raises(FleetValidation::ManifestError) do
      probe.send(:paginated_collection, path, "check_runs")
    end

    assert_includes error.message, "pagination remained full"
    assert_equal FleetValidation::PublicGitHubProbe::MAX_PAGES, client.requests.length
  end

  def test_later_workflow_page_supplies_smoke_and_review_app_discovery
    repo = "sanitized/demo"
    head = "a" * 40
    path = "/repos/#{repo}/actions/workflows?per_page=100"
    filler = Array.new(100) do |index|
      { "id" => index, "path" => ".github/workflows/filler-#{index}.yml", "name" => "Filler #{index}" }
    end
    caller = {
      "id" => 4100,
      "path" => ".github/workflows/ci.yml",
      "name" => "CI",
      "html_url" => "https://example.invalid/ci"
    }
    review = {
      "id" => 4200,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Review app",
      "state" => "active",
      "html_url" => "https://example.invalid/review"
    }
    responses = {
      path => { "workflows" => filler },
      "#{path}&page=2" => { "workflows" => [caller, review] },
      "/repos/#{repo}/actions/workflows/4100/runs?branch=main&per_page=100" => {
        "workflow_runs" => [{
          "id" => 4101,
          "head_sha" => head,
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/smoke-run"
        }]
      },
      "/repos/#{repo}/actions/runs/4101/jobs?per_page=100" => {
        "jobs" => [{
          "name" => "Fleet / Demo fleet smoke",
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/smoke-job"
        }]
      },
      "/repos/#{repo}/actions/workflows/4200/runs?event=pull_request&per_page=100" => {
        "workflow_runs" => [valid_review_run]
      }
    }
    client = Struct.new(:responses) do
      def get(path)
        responses.fetch(path)
      end

      def content(_repo, path, ref:)
        raise "wrong head" unless ref == "a" * 40
        return YAML.dump("jobs" => {}) unless path == ".github/workflows/ci.yml"

        YAML.dump(
          "jobs" => {
            "fleet" => {
              "name" => "Fleet",
              "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
            }
          }
        )
      end
    end.new(responses)
    probe = public_github_probe(client:)

    workflows = probe.send(:paginated_collection, path, "workflows")
    smoke = probe.send(:smoke_status, repo, head, [], workflows, default_branch: "main")
    review_app = probe.send(
      :review_app_status,
      repo,
      @contract.targets.first,
      workflows,
      default_branch: "main",
      observed_at: "2026-07-18T12:00:00Z"
    )

    assert_equal 102, workflows.length
    assert_equal "passed", smoke.fetch("status")
    assert_equal "passed", review_app.fetch("status")
  end

  def test_exact_head_smoke_run_can_appear_after_the_first_page
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = {
      "id" => 41,
      "path" => ".github/workflows/ci.yml",
      "html_url" => "https://example.invalid/workflow"
    }
    runs_path = "/repos/#{repo}/actions/workflows/41/runs?branch=main&per_page=100"
    jobs_path = "/repos/#{repo}/actions/runs/4101/jobs?per_page=100"
    filler_run = {
      "head_sha" => "b" * 40,
      "status" => "completed",
      "conclusion" => "success"
    }
    responses = {
      runs_path => { "workflow_runs" => Array.new(100) { filler_run.dup } },
      "#{runs_path}&page=2" => {
        "workflow_runs" => [{
          "id" => 4101,
          "head_sha" => head,
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/run"
        }]
      },
      jobs_path => {
        "jobs" => [{
          "name" => "Fleet / Demo fleet smoke",
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/job"
        }]
      }
    }
    client = Struct.new(:responses, :requests) do
      def get(path)
        requests << path
        responses.fetch(path)
      end
    end.new(responses, [])
    probe = public_github_probe(client:)
    caller = { "key" => "fleet", "name" => "Fleet" }

    status = probe.send(:shared_smoke_workflow_status, repo, head, "main", workflow, caller)

    assert_equal "passed", status.fetch("status")
    assert_includes client.requests, "#{runs_path}&page=2"
  end

  def test_called_reusable_smoke_job_can_appear_after_the_first_page
    repo = "sanitized/demo"
    run = { "id" => 4101 }
    jobs_path = "/repos/#{repo}/actions/runs/4101/jobs?per_page=100"
    filler_job = {
      "name" => "Unrelated",
      "status" => "completed",
      "conclusion" => "success"
    }
    responses = {
      jobs_path => { "jobs" => Array.new(100) { filler_job.dup } },
      "#{jobs_path}&page=2" => {
        "jobs" => [{
          "name" => "Fleet / Demo fleet smoke",
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/job"
        }]
      }
    }
    client = Struct.new(:responses, :requests) do
      def get(path)
        requests << path
        responses.fetch(path)
      end
    end.new(responses, [])
    probe = public_github_probe(client:)
    caller = { "key" => "fleet", "name" => "Fleet" }

    status = probe.send(:shared_smoke_job_status, repo, run, caller)

    assert_equal "passed", status.fetch("status")
    assert_includes client.requests, "#{jobs_path}&page=2"
  end

  def test_eligible_review_app_run_can_appear_after_the_first_page
    repo = "sanitized/demo"
    workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "state" => "active",
      "html_url" => "https://example.invalid/workflow"
    }
    runs_path = "/repos/#{repo}/actions/workflows/42/runs?event=pull_request&per_page=100"
    filler_run = {
      "pull_requests" => [{ "base" => { "ref" => "develop" } }]
    }
    responses = {
      runs_path => { "workflow_runs" => Array.new(100) { filler_run.dup } },
      "#{runs_path}&page=2" => { "workflow_runs" => [valid_review_run] }
    }
    client = Struct.new(:responses, :requests) do
      def get(path)
        requests << path
        responses.fetch(path)
      end
    end.new(responses, [])
    probe = public_github_probe(client:)

    status = probe.send(
      :review_workflow_status,
      repo,
      workflow,
      default_branch: "main",
      observed_at: "2026-07-18T12:00:00Z"
    )

    assert_equal "passed", status.fetch("status")
    assert_includes client.requests, "#{runs_path}&page=2"
  end

  def test_observe_degrades_malformed_and_full_bound_nested_collections_to_unknown
    target = @contract.targets.first
    repo = target.fetch("name")
    head = "a" * 40
    smoke_workflow = {
      "id" => 41,
      "path" => ".github/workflows/ci.yml",
      "html_url" => "https://example.invalid/smoke-workflow"
    }
    review_workflow = {
      "id" => 42,
      "path" => target.fetch("review_app_workflow"),
      "state" => "active",
      "html_url" => "https://example.invalid/review-workflow"
    }
    checks_path = "/repos/#{repo}/commits/#{head}/check-runs?per_page=100"
    workflows_path = "/repos/#{repo}/actions/workflows?per_page=100"
    smoke_runs_path = "/repos/#{repo}/actions/workflows/41/runs?branch=main&per_page=100"
    jobs_path = "/repos/#{repo}/actions/runs/4101/jobs?per_page=100"
    review_runs_path = "/repos/#{repo}/actions/workflows/42/runs?event=pull_request&per_page=100"
    requests = []
    client = Object.new
    client.define_singleton_method(:get) do |path|
      requests << path
      case path
      when "/repos/#{repo}"
        { "visibility" => "public", "default_branch" => "main", "archived" => false }
      when "/repos/#{repo}/commits/main"
        { "sha" => head }
      when checks_path
        { "check_runs" => [] }
      when workflows_path
        { "workflows" => [smoke_workflow, review_workflow] }
      when "/repos/#{repo}/dependency-graph/sbom"
        {}
      when smoke_runs_path
        {
          "workflow_runs" => [{
            "id" => 4101,
            "head_sha" => head,
            "status" => "completed",
            "conclusion" => "success"
          }]
        }
      when jobs_path
        { "jobs" => {} }
      else
        raise "unexpected path #{path}" unless path.start_with?(review_runs_path)

        { "workflow_runs" => Array.new(100) { { "pull_requests" => [] } } }
      end
    end
    dependabot_config = dependabot_v1_config
    client.define_singleton_method(:content) do |_repo, path, ref:|
      raise "wrong head" unless ref == head

      case path
      when smoke_workflow.fetch("path")
        YAML.dump(
          "jobs" => {
            "fleet" => {
              "name" => "Fleet",
              "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
            }
          }
        )
      when review_workflow.fetch("path")
        YAML.dump("jobs" => {})
      when ".github/dependabot.yml"
        YAML.dump(dependabot_config)
      else
        raise "unexpected content path #{path}"
      end
    end

    observation = public_github_probe(client:).observe(
      target,
      observed_at: "2026-07-18T12:00:00Z"
    )

    assert_equal head, observation.fetch("default_commit")
    assert_equal "unknown", observation.dig("smoke", "status")
    assert_equal "unknown", observation.dig("review_app", "status")
    assert_includes observation.dig("smoke", "evidence"), "ManifestError"
    assert_includes observation.dig("review_app", "evidence"), "ManifestError"
    assert_equal FleetValidation::PublicGitHubProbe::MAX_PAGES,
                 (requests.count { |path| path.start_with?(review_runs_path) })
  end

  def test_workflow_pagination_rejects_malformed_and_incomplete_pages
    path = "/repos/sanitized/demo/actions/workflows?per_page=100"
    malformed_client = Struct.new(:path) do
      def get(request_path)
        raise "unexpected path" unless request_path == path

        { "workflows" => {} }
      end
    end.new(path)
    error = assert_raises(FleetValidation::ManifestError) do
      public_github_probe(client: malformed_client)
        .send(:paginated_collection, path, "workflows")
    end
    assert_includes error.message, "is not an array"

    requests = []
    full_client = Object.new
    full_client.define_singleton_method(:get) do |request_path|
      requests << request_path
      { "workflows" => Array.new(100) { { "path" => ".github/workflows/filler.yml" } } }
    end
    error = assert_raises(FleetValidation::ManifestError) do
      public_github_probe(client: full_client)
        .send(:paginated_collection, path, "workflows")
    end
    assert_includes error.message, "pagination remained full"
    assert_equal FleetValidation::PublicGitHubProbe::MAX_PAGES, requests.length
  end

  def test_public_github_probe_binds_health_evidence_to_the_default_head
    target = @contract.targets.first
    repo = target.fetch("name")
    client = Struct.new(:responses, :contents) do
      def get(path)
        responses.fetch(path)
      end

      def content(repo_name, path, ref:)
        contents.fetch([repo_name, path, ref])
      end
    end.new(
      {
        "/repos/#{repo}" => { "visibility" => "public", "default_branch" => "main", "archived" => false },
        "/repos/#{repo}/commits/main" => {
          "sha" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "commit" => { "committer" => { "date" => "2026-07-17T12:00:00Z" } }
        },
        "/repos/#{repo}/dependency-graph/sbom" => {
          "sbom" => {
            "SPDXID" => "SPDXRef-DOCUMENT",
            "packages" => [
              { "SPDXID" => "SPDXRef-Root", "name" => "demo" },
              {
                "SPDXID" => "SPDXRef-Gem",
                "externalRefs" => [
                  { "referenceType" => "purl", "referenceLocator" => "pkg:gem/react_on_rails@17.0.0" }
                ]
              },
              {
                "SPDXID" => "SPDXRef-Npm",
                "externalRefs" => [
                  { "referenceType" => "purl", "referenceLocator" => "pkg:npm/react-on-rails@17.0.0" }
                ]
              }
            ],
            "relationships" => [
              {
                "spdxElementId" => "SPDXRef-DOCUMENT",
                "relationshipType" => "DESCRIBES",
                "relatedSpdxElement" => "SPDXRef-Root"
              },
              {
                "spdxElementId" => "SPDXRef-Root",
                "relationshipType" => "DEPENDS_ON",
                "relatedSpdxElement" => "SPDXRef-Gem"
              },
              {
                "spdxElementId" => "SPDXRef-Root",
                "relationshipType" => "DEPENDS_ON",
                "relatedSpdxElement" => "SPDXRef-Npm"
              }
            ]
          }
        },
        "/repos/#{repo}/commits/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/check-runs?per_page=100" => {
          "check_runs" => [
            { "name" => "CI", "status" => "completed", "conclusion" => "success", "html_url" => "https://example.invalid/ci" },
            {
              "name" => "Demo fleet smoke",
              "status" => "completed",
              "conclusion" => "success",
              "html_url" => "https://example.invalid/smoke"
            }
          ]
        },
        "/repos/#{repo}/actions/workflows?per_page=100" => {
          "workflows" => Array.new(100) do |index|
            {
              "id" => index,
              "path" => ".github/workflows/filler-#{index}.yml",
              "name" => "Filler #{index}"
            }
          end
        },
        "/repos/#{repo}/actions/workflows?per_page=100&page=2" => {
          "workflows" => [
            {
              "id" => 41,
              "path" => ".github/workflows/demo-fleet-smoke.yml",
              "name" => "Demo fleet smoke",
              "html_url" => "https://example.invalid/smoke-workflow"
            },
            {
              "id" => 42,
              "path" => ".github/workflows/cpflow-deploy-review-app.yml",
              "name" => "Review app",
              "state" => "active",
              "html_url" => "https://example.invalid/workflow"
            }
          ]
        },
        "/repos/#{repo}/actions/workflows/41/runs?branch=main&per_page=100" => {
          "workflow_runs" => [{
            "id" => 4101,
            "head_sha" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "status" => "completed",
            "conclusion" => "success",
            "html_url" => "https://example.invalid/smoke-run",
            "updated_at" => "2026-07-18T10:00:00Z"
          }]
        },
        "/repos/#{repo}/actions/runs/4101/jobs?per_page=100" => {
          "jobs" => [{
            "name" => "Fleet / Demo fleet smoke",
            "status" => "completed",
            "conclusion" => "success",
            "html_url" => "https://example.invalid/smoke-job"
          }]
        },
        "/repos/#{repo}/actions/workflows/42/runs?event=pull_request&per_page=100" => {
          "workflow_runs" => [valid_review_run]
        }
      },
      {
        [
          repo,
          ".github/workflows/demo-fleet-smoke.yml",
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ] => YAML.dump(
          "name" => "CI",
          "jobs" => {
            "fleet" => {
              "name" => "Fleet",
              "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
            }
          }
        ),
        [
          repo,
          ".github/dependabot.yml",
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ] => YAML.dump(dependabot_v1_config)
      }
    )
    probe = public_github_probe(client:)

    observation = probe.observe(target, observed_at: "2026-07-18T12:00:00Z")

    assert_equal "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", observation.fetch("default_commit")
    assert_equal false, observation.fetch("repository_archived")
    assert_equal "passed", observation.dig("default_ci", "status")
    assert_equal true, observation.dig("smoke", "shared_contract")
    assert_equal "passed", observation.dig("review_app", "status")
    assert_includes observation.dig("review_app", "evidence"), "2026-07-18T10:00:00Z"
    assert_equal "passed", observation.dig("dependabot", "status")
  end

  def test_review_app_capability_distinguishes_broken_pending_and_missing_runs
    target = @contract.targets.first
    repo = target.fetch("name")
    workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Review app",
      "state" => "active",
      "html_url" => "https://example.invalid/workflow"
    }
    client = Struct.new(:runs) do
      def get(_path)
        { "workflow_runs" => runs }
      end
    end
    probe = public_github_probe(
      client: client.new([valid_review_run("conclusion" => "failure")])
    )

    broken = review_app_status(probe, repo, target, workflow)
    probe = public_github_probe(
      client: client.new([valid_review_run("status" => "in_progress", "conclusion" => nil)])
    )
    pending = review_app_status(probe, repo, target, workflow)
    probe = public_github_probe(
      client: client.new([valid_review_run("conclusion" => "skipped")])
    )
    skipped = review_app_status(probe, repo, target, workflow)
    probe = public_github_probe(client: client.new([]))
    missing_run = review_app_status(probe, repo, target, workflow)
    absent_workflow = review_app_status(probe, repo, target, nil)

    assert_equal "blocked", broken.fetch("status")
    assert_equal "unknown", pending.fetch("status")
    assert_equal "blocked", skipped.fetch("status")
    assert_equal "unknown", missing_run.fetch("status")
    assert_equal "unknown", absent_workflow.fetch("status")
  end

  def test_review_app_ignores_staging_when_policy_does_not_require_a_review_app
    target = @contract.targets.first.merge(
      "review_app" => "not_required",
      "review_app_workflow" => nil
    )
    staging_workflow = {
      "id" => 41,
      "path" => ".github/workflows/cpflow-deploy-staging.yml",
      "name" => "Deploy staging",
      "state" => "active",
      "html_url" => "https://example.invalid/staging-workflow"
    }
    client = Struct.new(:runs) do
      def get(_path)
        { "workflow_runs" => runs }
      end
    end.new([
              {
                "status" => "completed",
                "conclusion" => "success",
                "html_url" => "https://example.invalid/staging-run",
                "updated_at" => "2026-07-18T10:00:00Z"
              }
            ])
    status = public_github_probe(client:)
             .send(
               :review_app_status,
               target.fetch("name"),
               target,
               [staging_workflow],
               default_branch: "main",
               observed_at: "2026-07-18T12:00:00Z"
             )

    assert_equal "not_applicable", status.fetch("status")
  end

  def test_review_app_ignores_auxiliary_failure_when_exact_deploy_review_workflow_passes
    target = @contract.targets.first
    exact_workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Deploy review app",
      "state" => "active",
      "html_url" => "https://example.invalid/review-workflow"
    }
    cleanup_workflow = {
      "id" => 43,
      "path" => ".github/workflows/cpflow-cleanup-review-app.yml",
      "name" => "Cleanup review app",
      "state" => "active",
      "html_url" => "https://example.invalid/cleanup-workflow"
    }
    client = Struct.new(:responses) do
      def get(path)
        responses.fetch(path)
      end
    end.new({
              "/repos/#{target.fetch('name')}/actions/workflows/42/runs?event=pull_request&per_page=100" => {
                "workflow_runs" => [valid_review_run("html_url" => "https://example.invalid/review-run")]
              },
              "/repos/#{target.fetch('name')}/actions/workflows/43/runs?event=pull_request&per_page=100" => {
                "workflow_runs" => [valid_review_run(
                  "conclusion" => "failure",
                  "html_url" => "https://example.invalid/cleanup-run"
                )]
              }
            })
    status = public_github_probe(client:)
             .send(
               :review_app_status,
               target.fetch("name"),
               target,
               [exact_workflow, cleanup_workflow],
               default_branch: "main",
               observed_at: "2026-07-18T12:00:00Z"
             )

    assert_equal "passed", status.fetch("status")
    assert_includes status.fetch("evidence"), "review-run"
    refute_includes status.fetch("evidence"), "cleanup-run"
  end

  def test_review_app_rejects_non_pr_mismatched_and_stale_runs
    target = @contract.targets.first
    repo = target.fetch("name")
    workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Deploy review app",
      "state" => "active"
    }
    client = Struct.new(:runs) do
      def get(_path)
        { "workflow_runs" => runs }
      end
    end
    manual = review_app_status(
      public_github_probe(client: client.new([valid_review_run("event" => "workflow_dispatch")])),
      repo,
      target,
      workflow
    )
    mismatched_head = review_app_status(
      public_github_probe(client: client.new([valid_review_run("head_sha" => "b" * 40)])),
      repo,
      target,
      workflow
    )
    mismatched_branch = review_app_status(
      public_github_probe(client: client.new([valid_review_run("head_branch" => "other")])),
      repo,
      target,
      workflow
    )
    wrong_base = review_app_status(
      public_github_probe(
        client: client.new([valid_review_run(
          "pull_requests" => [{
            "head" => { "ref" => "feature/review-app", "sha" => "c" * 40 },
            "base" => { "ref" => "release/17.0.0" }
          }]
        )])
      ),
      repo,
      target,
      workflow
    )
    stale = review_app_status(
      public_github_probe(
        client: client.new([valid_review_run("run_started_at" => "2026-04-01T10:00:00Z")])
      ),
      repo,
      target,
      workflow
    )

    assert_equal "unknown", manual.fetch("status")
    assert_equal "unknown", mismatched_head.fetch("status")
    assert_equal "unknown", mismatched_branch.fetch("status")
    assert_equal "unknown", wrong_base.fetch("status")
    assert_equal "unknown", stale.fetch("status")
  end

  def test_review_app_skips_a_newer_invalid_run_for_an_older_valid_run
    target = @contract.targets.first
    repo = target.fetch("name")
    workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Deploy review app",
      "state" => "active"
    }
    newer_invalid = valid_review_run(
      "head_sha" => "b" * 40,
      "html_url" => "https://example.invalid/newer-invalid",
      "run_started_at" => "2026-07-18T11:00:00Z",
      "updated_at" => "2026-07-18T11:05:00Z"
    )
    older_valid = valid_review_run(
      "html_url" => "https://example.invalid/older-valid",
      "run_started_at" => "2026-07-18T10:00:00Z",
      "updated_at" => "2026-07-18T10:05:00Z"
    )
    client = Struct.new(:runs) do
      def get(_path)
        { "workflow_runs" => runs }
      end
    end.new([newer_invalid, older_valid])

    status = review_app_status(public_github_probe(client:), repo, target, workflow)

    assert_equal "passed", status.fetch("status")
    assert_includes status.fetch("evidence"), "older-valid"
    refute_includes status.fetch("evidence"), "newer-invalid"
  end

  def test_review_app_recency_uses_the_manifest_staleness_limit
    manifest = Marshal.load(Marshal.dump(@manifest))
    manifest.fetch("standing_health")["max_default_age_days"] = 1
    contract = build_contract(manifest)
    target = contract.targets.first
    repo = target.fetch("name")
    workflow = {
      "id" => 42,
      "path" => ".github/workflows/cpflow-deploy-review-app.yml",
      "name" => "Deploy review app",
      "state" => "active"
    }
    client = Struct.new(:run) do
      def get(_path)
        { "workflow_runs" => [run] }
      end
    end.new(valid_review_run("run_started_at" => "2026-07-16T12:00:00Z"))
    probe = public_github_probe(
      client:,
      max_default_age_days: contract.max_default_age_days
    )

    status = review_app_status(probe, repo, target, workflow)

    assert_equal "unknown", status.fetch("status")
    assert_includes status.fetch("evidence"), "run age exceeds 1 days"
  end

  def test_shared_smoke_requires_an_exact_head_run_of_the_shared_workflow
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = {
      "id" => 41,
      "path" => ".github/workflows/ci.yml",
      "name" => "CI",
      "html_url" => "https://example.invalid/workflow"
    }
    client = Struct.new(:contents) do
      def content(_repo, _path, ref:)
        raise "wrong head" unless ref == "a" * 40

        YAML.dump(
          "jobs" => {
            "fleet" => {
              "name" => "Fleet",
              "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
            }
          }
        )
      end

      def get(_path)
        { "workflow_runs" => [] }
      end
    end.new({})
    unrelated_check = {
      "name" => "Unrelated smoke",
      "status" => "completed",
      "conclusion" => "success",
      "html_url" => "https://example.invalid/unrelated"
    }

    status = public_github_probe(client:)
             .send(
               :smoke_status,
               repo,
               head,
               [unrelated_check],
               [workflow],
               default_branch: "main"
             )

    assert_equal true, status.fetch("shared_contract")
    assert_equal "unknown", status.fetch("status")
    refute_includes status.fetch("evidence"), "unrelated"
  end

  def test_shared_smoke_requires_the_called_reusable_job_to_succeed
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = {
      "id" => 41,
      "path" => ".github/workflows/ci.yml",
      "html_url" => "https://example.invalid/workflow"
    }
    responses = {
      "/repos/#{repo}/actions/workflows/41/runs?branch=main&per_page=100" => {
        "workflow_runs" => [{
          "id" => 4101,
          "head_sha" => head,
          "status" => "completed",
          "conclusion" => "success",
          "html_url" => "https://example.invalid/run"
        }]
      },
      "/repos/#{repo}/actions/runs/4101/jobs?per_page=100" => {
        "jobs" => [{
          "name" => "Fleet / Demo fleet smoke",
          "status" => "completed",
          "conclusion" => "skipped",
          "html_url" => "https://example.invalid/job"
        }]
      }
    }
    client = Struct.new(:responses) do
      def get(path)
        responses.fetch(path)
      end
    end.new(responses)
    probe = public_github_probe(client:)
    caller = { "key" => "fleet", "name" => "Fleet" }

    skipped = probe.send(:shared_smoke_workflow_status, repo, head, "main", workflow, caller)
    responses.fetch("/repos/#{repo}/actions/runs/4101/jobs?per_page=100")
             .fetch("jobs").first["conclusion"] = "success"
    passed = probe.send(:shared_smoke_workflow_status, repo, head, "main", workflow, caller)

    assert_equal "unknown", skipped.fetch("status")
    assert_equal "passed", passed.fetch("status")
    assert_includes passed.fetch("evidence"), "https://example.invalid/job"
  end

  def test_shared_smoke_rejects_an_unrelated_local_job_when_the_caller_is_skipped
    repo = "sanitized/demo"
    run = { "id" => 4101 }
    jobs_path = "/repos/#{repo}/actions/runs/4101/jobs?per_page=100"
    client = Struct.new(:jobs_path) do
      def get(path)
        raise "unexpected path" unless path == jobs_path

        {
          "jobs" => [
            {
              "name" => "Demo fleet smoke",
              "status" => "completed",
              "conclusion" => "success",
              "html_url" => "https://example.invalid/unrelated"
            },
            {
              "name" => "Fleet",
              "status" => "completed",
              "conclusion" => "skipped",
              "html_url" => "https://example.invalid/skipped-caller"
            }
          ]
        }
      end
    end.new(jobs_path)
    probe = public_github_probe(client:)
    caller = { "key" => "fleet", "name" => "Fleet" }

    status = probe.send(:shared_smoke_job_status, repo, run, caller)

    assert_equal "unknown", status.fetch("status")
    assert_includes status.fetch("evidence"), "caller_job=fleet"
    refute_includes status.fetch("evidence"), "https://example.invalid/unrelated"
  end

  def test_shared_smoke_fails_closed_on_ambiguous_caller_names
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = { "id" => 41, "path" => ".github/workflows/ci.yml" }
    content = YAML.dump(
      "jobs" => {
        "fleet_a" => {
          "name" => "Fleet",
          "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
        },
        "fleet_b" => {
          "name" => "Fleet",
          "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
        }
      }
    )
    client = Struct.new(:content_value) do
      def content(_repo, _path, ref:)
        raise "wrong head" unless ref == "a" * 40

        content_value
      end

      def get(_path)
        raise "ambiguous callers must fail before run lookup"
      end
    end.new(content)

    status = public_github_probe(client:)
             .send(
               :smoke_status,
               repo,
               head,
               [],
               [workflow],
               default_branch: "main"
             )

    assert_equal true, status.fetch("shared_contract")
    assert_equal "unknown", status.fetch("status")
    assert_includes status.fetch("evidence"), "ambiguous reusable caller name"
  end

  def test_shared_smoke_rejects_a_local_job_name_that_spoofs_the_called_job
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = { "id" => 41, "path" => ".github/workflows/ci.yml" }
    content = YAML.dump(
      "jobs" => {
        "fleet" => {
          "name" => "Fleet",
          "uses" => "shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
        },
        "spoof" => {
          "name" => "Fleet / Demo fleet smoke",
          "runs-on" => "ubuntu-latest",
          "steps" => [{ "run" => "true" }]
        }
      }
    )
    client = Struct.new(:content_value) do
      def content(_repo, _path, ref:)
        raise "wrong head" unless ref == "a" * 40

        content_value
      end

      def get(_path)
        raise "spoofing definition must fail before run lookup"
      end
    end.new(content)

    status = public_github_probe(client:)
             .send(
               :smoke_status,
               repo,
               head,
               [],
               [workflow],
               default_branch: "main"
             )

    assert_equal true, status.fetch("shared_contract")
    assert_equal "unknown", status.fetch("status")
    assert_includes status.fetch("evidence"), "collides with a non-reusable job"
  end

  def test_shared_smoke_ignores_raw_reference_outside_jobs_uses
    repo = "sanitized/demo"
    head = "a" * 40
    workflow = {
      "id" => 41,
      "path" => ".github/workflows/smoke.yml",
      "name" => "Smoke",
      "html_url" => "https://example.invalid/workflow"
    }
    content = YAML.dump(
      "jobs" => {
        "smoke" => {
          "runs-on" => "ubuntu-latest",
          "steps" => [{
            "run" => "echo shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main"
          }]
        }
      }
    )
    client = Struct.new(:content_value) do
      def content(_repo, _path, ref:)
        raise "wrong head" unless ref == "a" * 40

        content_value
      end

      def get(_path)
        {
          "workflow_runs" => [{
            "head_sha" => "a" * 40,
            "status" => "completed",
            "conclusion" => "success"
          }]
        }
      end
    end.new(content)

    status = public_github_probe(client:)
             .send(
               :smoke_status,
               repo,
               head,
               [],
               [workflow],
               default_branch: "main"
             )

    assert_equal false, status.fetch("shared_contract")
    assert_equal "unknown", status.fetch("status")
  end

  def test_public_github_probe_degrades_a_target_failure_to_unknown
    client = Object.new
    def client.get(_path)
      raise "public API unavailable"
    end

    observation = public_github_probe(client:).observe(
      @contract.targets.first,
      observed_at: "2026-07-18T12:00:00Z"
    )

    assert_nil observation.fetch("default_commit")
    assert_equal "unknown", observation.dig("default_ci", "status")
    assert_includes observation.dig("default_ci", "evidence"), "public API unavailable"
  end

  def test_reusable_smoke_workflow_is_read_only_and_emits_exact_head_evidence
    workflow = File.read(REUSABLE_SMOKE)

    assert_includes workflow, "workflow_call:"
    assert_includes workflow, "contents: read"
    assert_includes workflow, "ruby/setup-ruby@#{RUBY_SETUP_SHA}"
    assert_includes workflow, "fleet-smoke-evidence-${{ github.sha }}"
    assert_includes workflow, '"head_sha"'
    refute_includes workflow, "secrets: inherit"
    refute_includes workflow, "bundle exec ruby"
  end

  def test_reusable_smoke_workflow_rejects_blank_required_commands
    step = reusable_smoke_steps.find { |candidate| candidate["name"] == "Validate required commands" }
    assert step, "workflow must validate required commands before execution"

    env = {
      "INSTALL_COMMAND" => "bundle install",
      "BUILD_COMMAND" => " ",
      "SMOKE_COMMAND" => "bin/smoke"
    }
    _stdout, _stderr, status = Open3.capture3(env, "bash", "-lc", step.fetch("run"))

    refute status.success?
  end

  def test_reusable_smoke_evidence_requires_success_for_every_required_stage
    step = reusable_smoke_steps.find { |candidate| candidate["name"] == "Write exact-head smoke evidence" }
    assert step
    env = {
      "HEAD_SHA" => "a" * 40,
      "REPOSITORY" => "sanitized/demo",
      "VALIDATE_OUTCOME" => "success",
      "INSTALL_OUTCOME" => "cancelled",
      "TEST_OUTCOME" => "skipped",
      "BUILD_OUTCOME" => "success",
      "SMOKE_OUTCOME" => "success"
    }

    Dir.mktmpdir do |directory|
      _stdout, stderr, status = Open3.capture3(env, "bash", "-lc", step.fetch("run"), chdir: directory)
      assert status.success?, stderr
      evidence = JSON.parse(File.read(File.join(directory, "fleet-smoke-evidence.json")))

      assert_equal "blocked", evidence.fetch("status")
    end

    env["INSTALL_OUTCOME"] = "success"
    Dir.mktmpdir do |directory|
      _stdout, stderr, status = Open3.capture3(env, "bash", "-lc", step.fetch("run"), chdir: directory)
      assert status.success?, stderr
      evidence = JSON.parse(File.read(File.join(directory, "fleet-smoke-evidence.json")))

      assert_equal "passed", evidence.fetch("status")
    end
  end

  def test_scheduled_health_workflow_runs_live_scan_and_uploads_the_pack
    workflow = File.read(SCHEDULED_HEALTH)
    manifest = YAML.safe_load_file(MANIFEST, aliases: false)

    assert_includes workflow, "schedule:"
    assert_includes workflow, "workflow_dispatch:"
    assert_includes workflow, "uses: ./.github/actions/setup-bundle"
    refute_includes workflow, "uses: ruby/setup-ruby@"
    assert_includes workflow, "RELEASE_OVERRIDE"
    assert_includes workflow, "RSC_VERSION_OVERRIDE"
    refute_includes workflow, "default: v17.0.0"
    refute_includes workflow, "default: 19.2.1"
    assert_includes workflow, 'bundle exec ruby "$HEALTH_SCRIPT"'
    assert_includes workflow, "bundle exec ruby -rjson"
    assert_includes workflow, "check_fleet_health.rb"
    assert_includes workflow, "--live"
    assert_includes workflow, "actions/upload-artifact@v4"
    assert_includes workflow, "fleet-health.json"
    assert_match(/\Av\d+\.\d+\.\d+\z/, manifest.dig("standing_health", "stable_release"))
    assert Gem::Version.correct?(manifest.dig("standing_health", "rsc_version"))
  end

  def test_central_fleet_health_docs_use_the_repo_bundle
    skill = File.read(SKILL)
    rc_plan = File.read(RC_PLAN)
    runbook = File.read(RELEASE_RUNBOOK)

    refute_match(/^\s*ruby .*fleet_health/m, skill)
    refute_match(/^\s*ruby .*check_fleet_health/m, skill)
    assert_includes skill, "bundle exec ruby .agents/skills/run-fleet-validation/scripts/fleet_health_test.rb"
    assert_includes rc_plan, "bundle exec ruby .agents/skills/run-fleet-validation/scripts/check_fleet_health.rb"
    assert_includes runbook, "bundle exec ruby .agents/skills/run-fleet-validation/scripts/check_fleet_health.rb"
    assert_includes runbook, 'test -z "$(git status --porcelain)"'
    assert_includes runbook, 'POLICY_COMMIT="$(git rev-parse HEAD)"'
    assert_includes runbook, '--policy-commit "$POLICY_COMMIT"'
    assert_includes runbook, "--output-dir tmp/fleet-health-stable"
  end

  private

  def public_github_probe(client:, max_default_age_days: @contract.max_default_age_days)
    FleetValidation::PublicGitHubProbe.new(client:, max_default_age_days:)
  end

  def build_contract(manifest)
    FleetValidation::FleetHealth.new(
      manifest:,
      pack_id: "manifest-test",
      release: "v17.0.0",
      rsc_version: "19.2.1",
      policy_commit: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
      generated_at: "2026-07-18T12:00:00Z"
    )
  end

  def reusable_smoke_steps
    YAML.safe_load_file(REUSABLE_SMOKE, aliases: false).dig("jobs", "smoke", "steps")
  end

  def target(evidence, id)
    evidence.fetch("targets").find { |candidate| candidate.fetch("id") == id }
  end

  def review_app_status(probe, repo, target, workflow)
    probe.send(
      :review_app_status,
      repo,
      target,
      workflow ? [workflow] : [],
      default_branch: "main",
      observed_at: "2026-07-18T12:00:00Z"
    )
  end

  def valid_review_run(overrides = {})
    {
      "event" => "pull_request",
      "status" => "completed",
      "conclusion" => "success",
      "head_branch" => "feature/review-app",
      "head_sha" => "c" * 40,
      "run_started_at" => "2026-07-18T10:00:00Z",
      "updated_at" => "2026-07-18T10:05:00Z",
      "html_url" => "https://example.invalid/review-app-run",
      "pull_requests" => [{
        "head" => { "ref" => "feature/review-app", "sha" => "c" * 40 },
        "base" => { "ref" => "main" }
      }]
    }.merge(overrides)
  end

  def stable_registry_artifacts
    [
      {
        "ecosystem" => "gem",
        "name" => "react_on_rails",
        "version" => "17.0.0",
        "source" => "https://rubygems.org"
      },
      {
        "ecosystem" => "gem",
        "name" => "react_on_rails_pro",
        "version" => "17.0.0",
        "source" => "https://rubygems.org"
      },
      {
        "ecosystem" => "npm",
        "name" => "react-on-rails",
        "version" => "17.0.0",
        "source" => "https://registry.npmjs.org"
      },
      {
        "ecosystem" => "npm",
        "name" => "react-on-rails-pro",
        "version" => "17.0.0",
        "source" => "https://registry.npmjs.org"
      },
      {
        "ecosystem" => "npm",
        "name" => "react-on-rails-pro-node-renderer",
        "version" => "17.0.0",
        "source" => "https://registry.npmjs.org"
      },
      {
        "ecosystem" => "npm",
        "name" => "create-react-on-rails-app",
        "version" => "17.0.0",
        "source" => "https://registry.npmjs.org"
      },
      {
        "ecosystem" => "npm",
        "name" => "react-on-rails-rsc",
        "version" => "19.2.1",
        "source" => "https://registry.npmjs.org"
      }
    ]
  end

  def dependabot_v1_config
    {
      "version" => 2,
      "updates" => [
        {
          "package-ecosystem" => "bundler",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" },
          "groups" => { "react-on-rails" => { "patterns" => ["react_on_rails*"] } }
        },
        {
          "package-ecosystem" => "npm",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" },
          "groups" => { "react-on-rails" => { "patterns" => ["react-on-rails*"] } }
        },
        {
          "package-ecosystem" => "github-actions",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" }
        }
      ]
    }
  end
end
