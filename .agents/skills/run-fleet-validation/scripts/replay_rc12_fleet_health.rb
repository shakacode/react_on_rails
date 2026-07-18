#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require_relative "fleet_health"

module FleetValidation
  module RC12FleetHealthReplay
    module_function

    FIXTURE = File.expand_path("../fixtures/rc12-health-drift.yml", __dir__)

    def run
      fixture = YAML.safe_load_file(FIXTURE, aliases: false)
      contract = FleetHealth.new(
        manifest: fixture.fetch("manifest"),
        pack_id: "rc12-standing-health-replay",
        release: "v17.0.0",
        rsc_version: "19.2.1",
        policy_commit: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
        generated_at: "2026-07-18T12:00:00Z"
      )
      evidence = contract.evaluate(
        observations: fixture.fetch("observations"),
        registry_artifacts: stable_registry_artifacts
      )
      errors = SchemaValidator.new(contract.schema).errors(evidence)
      raise "schema errors: #{errors.join('; ')}" unless errors.empty?

      blocking_targets = evidence.dig("aggregate", "blocking_targets")
      report_only_targets = evidence.fetch("targets").count { |target| target["status"] == "reported" }
      raise "expected one active blocking target" unless blocking_targets.length == 1
      raise "expected two report-only targets" unless report_only_targets == 2

      puts "blocking_targets=#{blocking_targets.length}"
      puts "report_only_targets=#{report_only_targets}"
      puts "SANITIZED_RC12_FLEET_HEALTH_REPLAY_PASS"
      0
    rescue ManifestError, RuntimeError => e
      warn "SANITIZED_RC12_FLEET_HEALTH_REPLAY_FAIL: #{e.message}"
      1
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
          "ecosystem" => "npm",
          "name" => "react-on-rails",
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
  end
end

exit FleetValidation::RC12FleetHealthReplay.run if $PROGRAM_NAME == __FILE__
