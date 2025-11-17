#!/usr/bin/env ruby
# frozen_string_literal: true

# Shakapacker precompile hook for React on Rails - Shared Implementation
#
# This is the shared implementation used by both test dummy apps:
# - spec/dummy/bin/shakapacker-precompile-hook
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

# Build ReScript if needed
# rubocop:disable Metrics/CyclomaticComplexity
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
    warn "⚠️  Warning: package.json not found. Skipping ReScript build."
    return
  end

  package_json = JSON.parse(File.read(package_json_path))
  unless package_json.dig("scripts", "build:rescript")
    warn "⚠️  Warning: ReScript config found but no build:rescript script in package.json"
    warn "    Add a build:rescript script to your package.json to enable ReScript builds"
    return
  end

  Dir.chdir(rails_root) do
    # Cross-platform package manager detection
    if system("which yarn > /dev/null 2>&1")
      system("yarn", "build:rescript", exception: true)
    elsif system("which npm > /dev/null 2>&1")
      system("npm", "run", "build:rescript", exception: true)
    else
      warn "⚠️  Warning: Neither yarn nor npm found. Skipping ReScript build."
      return
    end

    puts "✅ ReScript build completed successfully"
  end
rescue StandardError => e
  warn "❌ ReScript build failed: #{e.message}"
  exit 1
end
# rubocop:enable Metrics/CyclomaticComplexity

# Generate React on Rails packs if needed
def generate_packs_if_needed
  rails_root = find_rails_root
  return unless rails_root

  initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
  return unless File.exist?(initializer_path)

  # Check if auto-pack generation is configured
  initializer_content = File.read(initializer_path)
  return unless initializer_content.match?(/^\s*config\.auto_load_bundle\s*=/) ||
                initializer_content.match?(/^\s*config\.components_subdirectory\s*=/)

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
if __FILE__ == $PROGRAM_NAME
  build_rescript_if_needed
  generate_packs_if_needed
end
