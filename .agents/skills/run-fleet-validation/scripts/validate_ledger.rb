#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "yaml"
require_relative "fleet_lifecycle"

module FleetValidation
  module LedgerCLI
    module_function

    def run(argv)
      options = {
        manifest_path: "internal/contributor-info/demo-fleet.yml",
        ledger_path: nil,
        expected_candidate: nil,
        tracker_path: nil
      }
      parser = option_parser(options)
      parser.parse!(argv)
      raise OptionParser::MissingArgument, "--ledger" unless options[:ledger_path]
      raise OptionParser::MissingArgument, "--expected-candidate" unless options[:expected_candidate]

      manifest = YAML.safe_load_file(options.fetch(:manifest_path), aliases: false)
      ledger = JSON.parse(File.read(options.fetch(:ledger_path)))
      pack = ledger.is_a?(Hash) && ledger["pack"].is_a?(Hash) ? ledger["pack"] : {}
      lifecycle = Lifecycle.new(
        manifest:,
        pack_id: pack["pack_id"].to_s,
        release_selector: pack["release_selector"].to_s
      )
      errors = SchemaValidator.new(lifecycle.schema).errors(ledger)
      unless errors.empty?
        errors.each { |error| warn "ERROR: #{error}" }
        return 1
      end

      errors.concat(LedgerValidator.new(
        ledger,
        inventory: lifecycle.inventory,
        required_paths: lifecycle.required_paths,
        expected_candidate: options[:expected_candidate],
        expected_snapshot_fingerprint: lifecycle.snapshot_fingerprint,
        closeout: true
      ).errors)

      unless errors.empty?
        errors.each { |error| warn "ERROR: #{error}" }
        return 1
      end

      if options[:tracker_path]
        File.write(options.fetch(:tracker_path), TrackerRenderer.new(ledger).render)
      end
      puts "VALID fleet result ledger"
      0
    rescue Errno::ENOENT, JSON::ParserError, Psych::Exception, ManifestError, OptionParser::ParseError => e
      warn "ERROR: #{e.message}"
      warn parser
      1
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: validate_ledger.rb --ledger PATH [options]"
        parser.on("--manifest PATH", "Fleet manifest path") { |value| options[:manifest_path] = value }
        parser.on("--ledger PATH", "Result ledger JSON path") { |value| options[:ledger_path] = value }
        parser.on("--expected-candidate TAG", "Require this exact candidate") do |value|
          options[:expected_candidate] = value
        end
        parser.on("--render-tracker PATH", "Write append-only tracker Markdown") do |value|
          options[:tracker_path] = value
        end
      end
    end
  end
end

exit FleetValidation::LedgerCLI.run(ARGV) if $PROGRAM_NAME == __FILE__
