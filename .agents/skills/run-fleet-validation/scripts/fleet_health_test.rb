#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"
require_relative "fleet_health"

class FleetHealthTest < Minitest::Test
  FIXTURE = File.expand_path("../fixtures/rc12-health-drift.yml", __dir__)
  RC12_REPLAY = File.expand_path("replay_rc12_fleet_health.rb", __dir__)
  CHECK_FLEET_HEALTH = File.expand_path("check_fleet_health.rb", __dir__)
  REUSABLE_SMOKE = File.expand_path("../../../../.github/workflows/demo-fleet-smoke.yml", __dir__)
  SCHEDULED_HEALTH = File.expand_path("../../../../.github/workflows/demo-fleet-health.yml", __dir__)

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
    assert_equal "blocked", evidence.dig("aggregate", "status")
    assert_equal ["sanitized-active-drifted"], evidence.dig("aggregate", "blocking_targets")
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
    stdout, stderr, status = Open3.capture3("ruby", RC12_REPLAY)

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
        "ruby", CHECK_FLEET_HEALTH,
        "--manifest", manifest_path,
        "--observations", observations_path,
        "--registry-artifacts", registry_path,
        "--release", "v17.0.0",
        "--rsc-version", "19.2.1",
        "--pack-id", "offline-test",
        "--policy-commit", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        "--generated-at", "2026-07-18T12:00:00Z",
        "--output-dir", output_dir
      )

      assert status.success?, stderr
      assert File.exist?(File.join(output_dir, "fleet-health.json"))
    end
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

  def test_public_registry_resolver_rejects_an_incomplete_product_suite
    resolver = FleetValidation::PublicRegistryResolver.new(fetcher: lambda do |url|
      next [] if url.end_with?("react_on_rails_pro.json")

      if url.include?("rubygems.org")
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
        "/repos/#{repo}" => { "default_branch" => "main", "archived" => false },
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
          "workflows" => [
            { "path" => ".github/workflows/demo-fleet-smoke.yml", "name" => "Demo fleet smoke" },
            {
              "id" => 42,
              "path" => ".github/workflows/cpflow-deploy-review-app.yml",
              "name" => "Review app",
              "state" => "active",
              "html_url" => "https://example.invalid/workflow"
            }
          ]
        },
        "/repos/#{repo}/actions/workflows/42/runs?per_page=1" => {
          "workflow_runs" => [
            {
              "status" => "completed",
              "conclusion" => "success",
              "html_url" => "https://example.invalid/review-app-run",
              "updated_at" => "2026-07-18T10:00:00Z"
            }
          ]
        }
      },
      {
        [
          repo,
          ".github/workflows/demo-fleet-smoke.yml",
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ] => "uses: shakacode/react_on_rails/.github/workflows/demo-fleet-smoke.yml@main",
        [
          repo,
          ".github/dependabot.yml",
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ] => YAML.dump(dependabot_v1_config)
      }
    )
    probe = FleetValidation::PublicGitHubProbe.new(client:)

    observation = probe.observe(target, observed_at: "2026-07-18T12:00:00Z")

    assert_equal "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", observation.fetch("default_commit")
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
    probe = FleetValidation::PublicGitHubProbe.new(client: client.new([
                                                                        {
                                                                          "status" => "completed",
                                                                          "conclusion" => "failure",
                                                                          "html_url" => "https://example.invalid/run",
                                                                          "updated_at" => "2026-07-18T10:00:00Z"
                                                                        }
                                                                      ]))

    broken = probe.send(:review_app_status, repo, target, [workflow])
    probe = FleetValidation::PublicGitHubProbe.new(client: client.new([
                                                                        { "status" => "in_progress", "html_url" => "https://example.invalid/run", "updated_at" => "2026-07-18T11:00:00Z" }
                                                                      ]))
    pending = probe.send(:review_app_status, repo, target, [workflow])
    probe = FleetValidation::PublicGitHubProbe.new(client: client.new([]))
    missing_run = probe.send(:review_app_status, repo, target, [workflow])
    absent_workflow = probe.send(:review_app_status, repo, target, [])

    assert_equal "blocked", broken.fetch("status")
    assert_equal "unknown", pending.fetch("status")
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
    status = FleetValidation::PublicGitHubProbe.new(client:)
                                               .send(:review_app_status, target.fetch("name"), target, [staging_workflow])

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
              "/repos/#{target.fetch('name')}/actions/workflows/42/runs?per_page=1" => {
                "workflow_runs" => [
                  {
                    "status" => "completed",
                    "conclusion" => "success",
                    "html_url" => "https://example.invalid/review-run",
                    "updated_at" => "2026-07-18T10:00:00Z"
                  }
                ]
              },
              "/repos/#{target.fetch('name')}/actions/workflows/43/runs?per_page=1" => {
                "workflow_runs" => [
                  {
                    "status" => "completed",
                    "conclusion" => "failure",
                    "html_url" => "https://example.invalid/cleanup-run",
                    "updated_at" => "2026-07-18T11:00:00Z"
                  }
                ]
              }
            })
    status = FleetValidation::PublicGitHubProbe.new(client:)
                                               .send(
                                                 :review_app_status,
                                                 target.fetch("name"),
                                                 target,
                                                 [exact_workflow, cleanup_workflow]
                                               )

    assert_equal "passed", status.fetch("status")
    assert_includes status.fetch("evidence"), "review-run"
    refute_includes status.fetch("evidence"), "cleanup-run"
  end

  def test_public_github_probe_degrades_a_target_failure_to_unknown
    client = Object.new
    def client.get(_path)
      raise "public API unavailable"
    end

    observation = FleetValidation::PublicGitHubProbe.new(client:).observe(
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
    assert_includes workflow, "fleet-smoke-evidence-${{ github.sha }}"
    assert_includes workflow, '"head_sha"'
    refute_includes workflow, "secrets: inherit"
  end

  def test_scheduled_health_workflow_runs_live_scan_and_uploads_the_pack
    workflow = File.read(SCHEDULED_HEALTH)

    assert_includes workflow, "schedule:"
    assert_includes workflow, "workflow_dispatch:"
    assert_includes workflow, "check_fleet_health.rb"
    assert_includes workflow, "--live"
    assert_includes workflow, "actions/upload-artifact@v4"
    assert_includes workflow, "fleet-health.json"
  end

  private

  def target(evidence, id)
    evidence.fetch("targets").find { |candidate| candidate.fetch("id") == id }
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
