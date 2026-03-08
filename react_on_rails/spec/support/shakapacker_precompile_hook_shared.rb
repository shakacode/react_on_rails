#!/usr/bin/env ruby
# frozen_string_literal: true

# Shakapacker precompile hook for React on Rails - Shared Implementation
#
# This is the shared implementation used by both test dummy apps:
# - react_on_rails/spec/dummy/bin/shakapacker-precompile-hook
# - react_on_rails_pro/spec/dummy/bin/shakapacker-precompile-hook
#
# This script runs before webpack compilation to:
# 1. Build ReScript files (if configured)
# 2. Generate pack files for auto-bundled components
#
# See: https://github.com/shakacode/shakapacker/blob/main/docs/precompile_hook.md

require "fileutils"
require "json"

# Find Rails root by walking upward looking for config/environment.rb
def find_rails_root
  dir = Dir.pwd
  while dir != "/"
    return dir if File.exist?(File.join(dir, "config", "environment.rb"))

    dir = File.dirname(dir)
  end
  nil
end

# Detect which package manager to use based on package.json's packageManager field,
# falling back to checking system availability
def detect_package_manager(package_json)
  pkg_manager = package_json["packageManager"]
  case pkg_manager
  when /\Apnpm@/ then "pnpm"
  when /\Ayarn@/ then "yarn"
  when /\Anpm@/ then "npm"
  else
    # No packageManager field; fall back to system detection
    %w[pnpm yarn npm].find { |pm| system("which #{pm} > /dev/null 2>&1") }
  end
end

# Build ReScript if needed
# rubocop:disable Metrics/AbcSize
def build_rescript_if_needed
  rails_root = find_rails_root
  unless rails_root
    warn "⚠️  Warning: Could not find Rails root. Skipping ReScript build."
    return
  end

  # Check for both old (bsconfig.json) and new (rescript.json) config files
  return unless File.exist?(File.join(rails_root, "bsconfig.json")) ||
                File.exist?(File.join(rails_root, "rescript.json"))

  puts "🔧 Building ReScript..."

  # Validate that build:rescript script exists in package.json
  package_json_path = File.join(rails_root, "package.json")
  unless File.exist?(package_json_path)
    warn "❌ Error: ReScript config found but package.json not found"
    warn "    ReScript requires a package.json with a build:rescript script"
    exit 1
  end

  package_json = JSON.parse(File.read(package_json_path))
  unless package_json.dig("scripts", "build:rescript")
    warn "❌ Error: ReScript config found but no build:rescript script in package.json"
    warn "    Add this to your package.json scripts section:"
    warn '    "build:rescript": "rescript build"'
    exit 1
  end

  Dir.chdir(rails_root) do
    pm = detect_package_manager(package_json)
    unless pm
      warn "❌ Error: No package manager found but ReScript build required"
      warn "    Install pnpm, yarn, or npm to build ReScript files"
      exit 1
    end

    system(pm, "run", "build:rescript", exception: true)
    puts "✅ ReScript build completed successfully"
  end
rescue JSON::ParserError => e
  warn "❌ Error: Invalid package.json: #{e.message}"
  exit 1
rescue StandardError => e
  warn "❌ ReScript build failed: #{e.message}"
  exit 1
end
# rubocop:enable Metrics/AbcSize

# Generate React on Rails packs if needed
def generate_packs_if_needed
  rails_root = find_rails_root
  return unless rails_root

  initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
  return unless File.exist?(initializer_path)

  # Check if auto-pack generation is configured
  # Match config lines that aren't commented out and allow flexible spacing
  initializer_content = File.read(initializer_path)
  return unless initializer_content.match?(/^\s*(?!#).*config\.auto_load_bundle\s*=/) ||
                initializer_content.match?(/^\s*(?!#).*config\.components_subdirectory\s*=/)

  puts "📦 Generating React on Rails packs..."

  Dir.chdir(rails_root) do
    # Skip validation during precompile hook execution
    ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true"

    # Run pack generation
    system("bundle", "exec", "rails", "react_on_rails:generate_packs", exception: true)
    puts "✅ Pack generation completed successfully"
  end
rescue Errno::ENOENT => e
  warn "⚠️  Warning: #{e.message}"
rescue StandardError => e
  warn "❌ Pack generation failed: #{e.message}"
  exit 1
end

# Main execution (only if run directly, not when required)
def run_precompile_tasks
  build_rescript_if_needed
  generate_packs_if_needed
end

run_precompile_tasks if __FILE__ == $PROGRAM_NAME
