# frozen_string_literal: true

require_relative "../react_on_rails/license_scanner"

begin
  require "rainbow"
rescue LoadError
  # Fallback if Rainbow is not available
  module Kernel
    def Rainbow(text) # rubocop:disable Naming/MethodName
      text
    end
  end
end

namespace :react_on_rails do
  desc "Scan all dependencies for disallowed licenses (GPL, AGPL)"
  task :scan_licenses do
    format = ENV.fetch("FORMAT", "text")
    scanner = ReactOnRails::LicenseScanner.new
    result = scanner.scan

    if format.casecmp("json").zero?
      print_json_result(result)
    else
      print_text_result(result)
    end

    exit(1) if result.violations.any?
  end
end

def print_json_result(result)
  require "json"
  output = {
    status: result.violations.any? ? "fail" : "pass",
    scanned: result.scanned_count,
    violations: result.violations.map { |v| violation_hash(v) },
    warnings: result.warnings.map { |v| violation_hash(v) }
  }
  puts JSON.pretty_generate(output)
end

def violation_hash(violation)
  {
    name: violation.name,
    version: violation.version,
    licenses: violation.licenses,
    source: violation.source
  }
end

def print_text_result(result)
  puts Rainbow("\nReact on Rails License Scan").bold
  puts Rainbow("=" * 40).cyan
  puts "Scanned #{result.scanned_count} dependencies\n\n"

  print_violations(result.violations) if result.violations.any?
  print_warnings(result.warnings) if result.warnings.any?
  print_summary(result.violations)
end

def print_violations(violations)
  puts Rainbow("VIOLATIONS (disallowed licenses):").red.bold
  violations.each do |v|
    puts Rainbow("  ✗ #{v.name} #{v.version} (#{v.source})").red
    puts "    Licenses: #{v.licenses.join(', ')}"
  end
  puts
end

def print_warnings(warnings)
  puts Rainbow("WARNINGS (multi-licensed with copyleft option):").yellow.bold
  warnings.each do |v|
    puts Rainbow("  ⚠ #{v.name} #{v.version} (#{v.source})").yellow
    puts "    Licenses: #{v.licenses.join(', ')} (permissive option available)"
  end
  puts
end

def print_summary(violations)
  if violations.empty?
    puts Rainbow("✓ No disallowed licenses found").green.bold
  else
    puts Rainbow("✗ #{violations.size} violation(s) found").red.bold
    puts "  Disallowed: #{ReactOnRails::LicenseScanner::DISALLOWED_LICENSES.join(', ')}"
  end
  puts
end
