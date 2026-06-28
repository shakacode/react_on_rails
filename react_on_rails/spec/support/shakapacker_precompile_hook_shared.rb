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
require "find"
require "json"

# Guarded so the specs, which `load` this script once per example, don't warn on constant
# re-initialization (the script is also run directly as the precompile hook).
unless defined?(EXCLUDED_RSC_REGISTRATION_ENTRY_PATH_COMPONENTS)
  EXCLUDED_RSC_REGISTRATION_ENTRY_PATH_COMPONENTS = %w[.git log node_modules public spec test tmp vendor].freeze
end
unless defined?(RSC_REGISTRATION_ENTRY_PATH_ENV)
  RSC_REGISTRATION_ENTRY_PATH_ENV = "REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH"
end

# Find Rails root by walking upward looking for config/environment.rb
def find_rails_root
  dir = Dir.pwd
  while dir != "/"
    return dir if File.exist?(File.join(dir, "config", "environment.rb"))

    dir = File.dirname(dir)
  end
  nil
end

# Build the env for a spawned `bundle exec` / shakapacker child so it can read the UTF-8 files in
# the bundle (Gemfiles, and dependency gemspecs that carry accented author names, etc.).
#
# We intervene ONLY under a bare C/POSIX locale, where the locale-derived encoding is US-ASCII and
# the child dies on the first non-ASCII byte with "invalid byte sequence in US-ASCII". US-ASCII is a
# strict subset of UTF-8, so widening that child to UTF-8 is loss-free for genuinely-ASCII content.
#
# We deliberately do NOT touch a real national locale. A developer with, say, LANG=pt_BR.ISO8859-1
# has a non-US-ASCII locale and latin-1/CP1252 source files that Ruby already reads correctly;
# forcing UTF-8 there would re-decode those files and raise the very "invalid byte sequence in
# UTF-8" error we are trying to avoid. Under that locale (and under a normal UTF-8 locale) we pass
# the caller's `extra` env through untouched and let the child inherit the working locale.
#
# The gate is Encoding.find("locale"), not Encoding.default_external: it reflects the encoding the
# child computes from the inherited locale and is immune to a runtime `Encoding.default_external =`
# override (e.g. the UTF-8 one Rails applies during boot when the shipped hook loads the env).
#
# `extra` keys (functional flags like REACT_ON_RAILS_SKIP_VALIDATION) are always applied.
def utf8_subprocess_env(extra = {})
  # US-ASCII (glibc) and ASCII-8BIT (some musl/empty-charmap C locales) both mean the libc reported
  # no real charset, so both are the bare C/POSIX fallback that is safe to widen to UTF-8.
  return extra.dup unless [Encoding::US_ASCII, Encoding::ASCII_8BIT].include?(Encoding.find("locale"))

  # Merge the UTF-8 widening last so it is authoritative: a caller-supplied key cannot accidentally
  # drop the pin (callers pass functional flags like REACT_ON_RAILS_SKIP_VALIDATION here, not locale
  # vars). The pin is derived from the parent's own RUBYOPT, so existing non-encoding flags survive.
  extra.merge(
    "LANG" => "C.UTF-8",
    "LC_ALL" => "C.UTF-8",
    "RUBYOPT" => utf8_widened_rubyopt(ENV.fetch("RUBYOPT", ""))
  )
end

# Prepend a UTF-8 external-encoding pin to RUBYOPT for the C/POSIX widening case — a portable
# fallback for systems where the C.UTF-8 locale is not installed and LANG/LC_ALL alone would not
# take effect. If RUBYOPT already pins an encoding it is an explicit, deliberate request that we
# honor rather than override or duplicate (Ruby raises "default_external already set" on a
# conflicting second -E).
def utf8_widened_rubyopt(rubyopt)
  return rubyopt if rubyopt_pins_encoding?(rubyopt)

  "-EUTF-8 #{rubyopt}".strip
end

# The only operand-consuming short options RUBYOPT accepts are -I (load path) and -r (require), and
# their operand can begin with E/K (e.g. -rEnglish, -rKconv), so a scan for a clustered encoding flag
# must stop at them. Every other operand-consuming option (-C/-e/-S/-x/-F/-0) is rejected by RUBYOPT
# outright ("invalid switch in RUBYOPT"), so it can never appear here.
ARGUMENT_TAKING_SHORT_RUBYOPT_SWITCHES = %w[I r].freeze unless defined?(ARGUMENT_TAKING_SHORT_RUBYOPT_SWITCHES)

# True when RUBYOPT already pins a source encoding: a -E/-K (including inside a short-option cluster
# such as -wEUS-ASCII), or a --encoding/--external-encoding/--internal-encoding long option.
def rubyopt_pins_encoding?(rubyopt)
  rubyopt.split.any? { |token| rubyopt_token_pins_encoding?(token) }
end

def rubyopt_token_pins_encoding?(token)
  return true if token.start_with?("--encoding", "--external-encoding", "--internal-encoding")
  return false unless token.start_with?("-") && !token.start_with?("--") && token.length > 1

  token[1..].each_char do |char|
    break if ARGUMENT_TAKING_SHORT_RUBYOPT_SWITCHES.include?(char)
    return true if "EK".include?(char)
  end
  false
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

  # Read as UTF-8 explicitly: under a C/POSIX locale (no LANG/LC_ALL), Encoding.default_external
  # is US-ASCII and non-ASCII content would raise when parsed or regex-matched.
  package_json = JSON.parse(File.read(package_json_path, mode: "r:bom|utf-8"))
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
  # Match config lines that aren't commented out and allow flexible spacing.
  # Read as UTF-8 explicitly: under a C/POSIX locale (no LANG/LC_ALL), Encoding.default_external
  # is US-ASCII and non-ASCII content would raise when regex-matched.
  initializer_content = File.read(initializer_path, mode: "r:bom|utf-8")
  return unless initializer_content.match?(/^\s*(?!#).*config\.auto_load_bundle\s*=/) ||
                initializer_content.match?(/^\s*(?!#).*config\.components_subdirectory\s*=/)

  puts "📦 Generating React on Rails packs..."

  Dir.chdir(rails_root) do
    # Skip validation during precompile hook execution.
    # Force a UTF-8 locale for the child so `bundle exec` can parse Gemfiles with non-ASCII bytes
    # under a C/POSIX locale (see utf8_subprocess_env).
    system(utf8_subprocess_env("REACT_ON_RAILS_SKIP_VALIDATION" => "true"),
           "bundle", "exec", "rails", "react_on_rails:generate_packs", exception: true)
    puts "✅ Pack generation completed successfully"
  end
rescue Errno::ENOENT => e
  warn "⚠️  Warning: #{e.message}"
rescue StandardError => e
  warn "❌ Pack generation failed: #{e.message}"
  exit 1
end

def rsc_registration_entry_path_components(path, rails_root: nil)
  expanded_path = File.expand_path(path)
  return [] if rails_root && expanded_path == File.expand_path(rails_root)

  if rails_root
    expanded_root = "#{File.expand_path(rails_root)}#{File::SEPARATOR}"
    expanded_path = expanded_path.delete_prefix(expanded_root) if expanded_path.start_with?(expanded_root)
  end

  expanded_path.split(File::SEPARATOR).reject(&:empty?)
end

def valid_rsc_registration_entry_path?(path, rails_root: nil)
  path_components = rsc_registration_entry_path_components(path, rails_root:)
  EXCLUDED_RSC_REGISTRATION_ENTRY_PATH_COMPONENTS.none? { |component| path_components.include?(component) }
end

def configured_rsc_manifest_registration_entry(rails_root)
  configured_path = ENV[RSC_REGISTRATION_ENTRY_PATH_ENV].to_s.strip
  return nil if configured_path.empty?

  path = File.expand_path(configured_path, rails_root)
  return nil unless File.file?(path)
  return nil unless File.basename(path) == "server-component-registration-entry.js"

  path if valid_rsc_registration_entry_path?(path, rails_root:)
end

def rsc_manifest_registration_entry(rails_root)
  configured_entry = configured_rsc_manifest_registration_entry(rails_root)
  return configured_entry if configured_entry

  Find.find(rails_root) do |path|
    if File.directory?(path)
      Find.prune unless valid_rsc_registration_entry_path?(path, rails_root:)
      next
    end

    next unless File.basename(path) == "server-component-registration-entry.js"
    next unless File.basename(File.dirname(path)) == "generated"

    return path if valid_rsc_registration_entry_path?(path, rails_root:)
  end

  nil
end

def clear_stale_rsc_manifest_client_references(rails_root)
  stale_manifest = File.join(rails_root, "ssr-generated", "rsc-client-references.json")
  FileUtils.rm_f(stale_manifest)
end

# Generate RSC manifest client references if a server component registration entry exists.
#
# Unlike the shipped template hook
# (lib/generators/react_on_rails/templates/base/base/bin/shakapacker-precompile-hook), which loads
# the full Rails environment and gates on `ReactOnRailsPro::Utils.rsc_support_enabled?`, this
# standalone script never requires `config/environment` (it only walks up for the Rails root), so
# ReactOnRailsPro is not loaded and `rsc_support_enabled?` is unavailable here. Instead it relies on
# the registration entry's absence as the capability signal: the entry is written only when RSC is
# enabled AND there is at least one server component to register (see
# PacksGenerator#create_server_component_registration_entry, which returns early when there are no
# server components), so a missing entry means there is nothing to discover (RSC off, or RSC on with
# no server components) and discovery is skipped. The early `RSC_REFERENCE_DISCOVERY_BUILD` guard
# prevents the discovery build (which re-invokes bin/shakapacker) from recursing into itself.
def generate_rsc_manifest_client_references_if_needed
  return if ENV["RSC_REFERENCE_DISCOVERY_BUILD"] == "true"

  rails_root = find_rails_root
  return unless rails_root

  registration_entry = rsc_manifest_registration_entry(rails_root)
  unless registration_entry
    clear_stale_rsc_manifest_client_references(rails_root)
    return
  end

  shakapacker_bin = File.join(rails_root, "bin", "shakapacker")
  unless File.exist?(shakapacker_bin)
    raise "bin/shakapacker is missing; cannot generate RSC manifest client references. " \
          "Restore bin/shakapacker before precompiling RSC assets."
  end

  puts "🔎 Generating RSC manifest client references..."

  # Force a UTF-8 locale so the shakapacker child (which loads the Gemfile via bundler/setup) does
  # not crash under a C/POSIX locale on Gemfiles with non-ASCII bytes (see utf8_subprocess_env).
  env = utf8_subprocess_env(
    # Set explicitly (rather than relying on the parent ENV that generate_packs_if_needed used to
    # mutate) so this discovery build still skips React on Rails config validation.
    "REACT_ON_RAILS_SKIP_VALIDATION" => "true",
    "SHAKAPACKER_SKIP_PRECOMPILE_HOOK" => "true",
    "RSC_REFERENCE_DISCOVERY_BUILD" => "true",
    "RSC_BUNDLE_ONLY" => "true",
    "CLIENT_BUNDLE_ONLY" => nil,
    "SERVER_BUNDLE_ONLY" => nil
  )

  Dir.chdir(rails_root) do
    system(env, shakapacker_bin, exception: true)
    puts "✅ RSC manifest client references generated successfully"
  end
# The discovered manifest is load-bearing for correct client references, so a failed discovery build
# must abort the precompile (exit 1) rather than warn — matching the template hook, which lets the
# error propagate to its top-level rescue. The shakapacker binary's existence is already asserted
# above, so any failure here (including Errno::ENOENT) is a real error, not a benign "tool missing".
rescue StandardError => e
  warn "❌ RSC manifest client reference generation failed: #{e.message}"
  warn e.backtrace.first(5).join("\n") if e.backtrace
  exit 1
end

# Generate i18n locale files if configured
def generate_locales_if_needed
  rails_root = find_rails_root
  return unless rails_root

  initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
  return unless File.exist?(initializer_path)

  # Check if i18n_dir is configured (not commented out)
  # Read as UTF-8 explicitly: under a C/POSIX locale (no LANG/LC_ALL), Encoding.default_external
  # is US-ASCII and non-ASCII content would raise when regex-matched.
  initializer_content = File.read(initializer_path, mode: "r:bom|utf-8")
  return unless initializer_content.match?(/^\s*config\.i18n_dir\s*=/)

  puts "🌐 Generating i18n locale files..."

  Dir.chdir(rails_root) do
    # Run locale generation (idempotent - skips if up-to-date). Pass env to subprocess only, not
    # globally. Force a UTF-8 locale so `bundle exec` can parse Gemfiles with non-ASCII bytes under
    # a C/POSIX locale (see utf8_subprocess_env).
    system(utf8_subprocess_env("REACT_ON_RAILS_SKIP_VALIDATION" => "true"),
           "bundle", "exec", "rake", "react_on_rails:locale", exception: true)
    puts "✅ Locale generation completed successfully"
  end
rescue StandardError => e
  warn "❌ Locale generation failed: #{e.message}"
  exit 1
end

# Main execution (only if run directly, not when required)
def run_precompile_tasks
  build_rescript_if_needed
  generate_locales_if_needed
  generate_packs_if_needed
  generate_rsc_manifest_client_references_if_needed
end

run_precompile_tasks if __FILE__ == $PROGRAM_NAME
