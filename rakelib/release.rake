# frozen_string_literal: true

require "bundler"
require "json"
require_relative "task_helpers"
require_relative File.join(gem_root, "lib", "react_on_rails", "version_syntax_converter")
require_relative File.join(gem_root, "lib", "react_on_rails", "git_utils")
require_relative File.join(gem_root, "lib", "react_on_rails", "utils")

class RaisingMessageHandler
  def add_error(error)
    raise error
  end
end

# Helper module for release-specific tasks
module ReleaseHelpers
  include ReactOnRails::TaskHelpers

  module_function

  # Publish a gem with retry logic for OTP failures
  def publish_gem_with_retry(dir, gem_name, max_retries: ENV.fetch("GEM_RELEASE_MAX_RETRIES", "3").to_i)
    puts "\nCarefully add your OTP for Rubygems when prompted."
    puts "NOTE: OTP codes expire quickly (typically 30 seconds). Generate a fresh code when prompted."

    retry_count = 0
    success = false

    while retry_count < max_retries && !success
      begin
        sh_in_dir(dir, "gem release")
        success = true
      rescue Gem::CommandException, IOError => e
        retry_count += 1
        if retry_count < max_retries
          puts "\n⚠️  #{gem_name} release failed (attempt #{retry_count}/#{max_retries})"
          puts "Common causes:"
          puts "  - OTP code expired or already used"
          puts "  - Network timeout"
          puts "\nGenerating a FRESH OTP code and retrying in 5 seconds..."
          sleep 5
        else
          puts "\n❌ Failed to publish #{gem_name} after #{max_retries} attempts"
          raise e
        end
      end
    end
  end
end

# rubocop:disable Metrics/BlockLength

desc("Unified release script for all React on Rails packages and gems.

IMPORTANT: This script uses UNIFIED VERSIONING - all packages (core + pro) will be
updated to the same version number and released together.

Version argument can be:
  - Semver bump type: 'patch', 'minor', or 'major' (e.g., 16.1.1 → 16.1.2, 16.2.0, or 17.0.0)
  - Explicit version: '16.2.0'
  - Pre-release version: '16.2.0.beta.1' (rubygem format with dots, converted to 16.2.0-beta.1 for NPM)

This will update and release:
  PUBLIC (npmjs.org + rubygems.org):
    - react-on-rails NPM package
    - react-on-rails-pro NPM package
    - react-on-rails-pro-node-renderer NPM package
    - react_on_rails RubyGem
    - react_on_rails_pro RubyGem

1st argument: Version (patch/minor/major OR explicit version like 16.2.0)
2nd argument: Dry run (true/false, default: false)
3rd argument: Registry (verdaccio/npm, default: npm)
4th argument: Skip push (skip_push to skip, default: push)

Examples:
  rake release[patch]                           # Bump patch version (16.1.1 → 16.1.2)
  rake release[minor]                           # Bump minor version (16.1.1 → 16.2.0)
  rake release[major]                           # Bump major version (16.1.1 → 17.0.0)
  rake release[16.2.0]                          # Set explicit version
  rake release[16.2.0.beta.1]                   # Set pre-release version (→ 16.2.0-beta.1 for NPM)
  rake release[patch,true]                      # Dry run
  rake release[16.2.0,false,verdaccio]          # Test with Verdaccio
  rake release[16.2.0,false,npm,skip_push]      # Release without pushing to remote")
task :release, %i[version dry_run registry skip_push] do |_t, args|
  include ReactOnRails::TaskHelpers

  # Check if there are uncommitted changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)
  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])

  # Validate registry parameter
  registry_value = args_hash.fetch(:registry, "")
  unless registry_value.empty? || registry_value == "verdaccio" || registry_value == "npm"
    raise ArgumentError,
          "Invalid registry value '#{registry_value}'. Valid values are: 'verdaccio', 'npm', or empty string"
  end

  use_verdaccio = registry_value == "verdaccio"

  # Validate skip_push parameter
  skip_push_value = args_hash.fetch(:skip_push, "")
  unless skip_push_value.empty? || skip_push_value == "skip_push"
    raise ArgumentError, "Invalid skip_push value '#{skip_push_value}'. Valid values are: 'skip_push' or empty string"
  end

  skip_push = skip_push_value == "skip_push"

  version_input = args_hash.fetch(:version, "")

  if version_input.strip.empty?
    raise ArgumentError,
          "Version argument is required. Use 'patch', 'minor', 'major', or explicit version (e.g., '16.2.0')"
  end

  # Having the examples prevents publishing
  Rake::Task["shakapacker_examples:clobber"].invoke
  # Delete any react_on_rails.gemspec except the root one
  sh_in_dir(gem_root, "find . -mindepth 2 -name 'react_on_rails.gemspec' -delete")
  # Delete any react_on_rails_pro.gemspec except the one in react_on_rails_pro directory
  sh_in_dir(gem_root, "find . -mindepth 3 -name 'react_on_rails_pro.gemspec' -delete")

  # Pull latest changes (skip in dry-run mode or when skip_push is set)
  sh_in_dir(gem_root, "git pull --rebase") unless is_dry_run || skip_push

  # Determine if version_input is semver keyword or explicit version
  semver_keywords = %w[patch minor major]
  is_semver_bump = semver_keywords.include?(version_input.strip.downcase)

  if is_semver_bump
    # Use gem bump with semver keyword
    puts "Bumping #{version_input} version for react_on_rails gem..."
  else
    # Use explicit version
    puts "Setting react_on_rails gem version to #{version_input}..."
  end
  sh_in_dir(gem_root, "gem bump --no-commit --version #{version_input}")

  # Read the actual version that was set for react_on_rails
  actual_gem_version = begin
    version_file = File.join(gem_root, "lib", "react_on_rails", "version.rb")
    version_content = File.read(version_file)
    version_content.match(/VERSION = "(.+)"/)[1]
  end

  actual_npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(actual_gem_version)

  puts "\n#{'=' * 80}"
  puts "UNIFIED VERSION: #{actual_gem_version} (gem) / #{actual_npm_version} (npm)"
  puts "=" * 80

  # Update react_on_rails_pro gem version to match
  puts "\nUpdating react_on_rails_pro gem version to #{actual_gem_version}..."
  pro_gem_root = File.join(gem_root, "react_on_rails_pro")
  pro_version_file = File.join(pro_gem_root, "lib", "react_on_rails_pro", "version.rb")
  pro_version_content = File.read(pro_version_file)
  # We use gsub instead of `gem bump` here because the git tree is already dirty
  # from bumping the core gem version above, and `gem bump` fails with uncommitted changes
  # Use word boundary \b to match only VERSION, not PROTOCOL_VERSION
  pro_version_content.gsub!(/\bVERSION = ".+"/, "VERSION = \"#{actual_gem_version}\"")
  File.write(pro_version_file, pro_version_content)
  puts "  Updated #{pro_version_file}"
  puts "  Note: react_on_rails_pro.gemspec will automatically use ReactOnRails::VERSION"

  puts "\nUpdating package.json files to version #{actual_npm_version}..."

  # Update all package.json files
  package_json_files = [
    File.join(gem_root, "package.json"),
    File.join(gem_root, "packages", "react-on-rails", "package.json"),
    File.join(gem_root, "packages", "react-on-rails-pro", "package.json"),
    File.join(gem_root, "react_on_rails_pro", "package.json")
  ]

  package_json_files.each do |file|
    content = JSON.parse(File.read(file))
    content["version"] = actual_npm_version

    # For react-on-rails-pro package, also update the react-on-rails dependency to exact version
    if content["name"] == "react-on-rails-pro"
      content["dependencies"] ||= {}
      content["dependencies"]["react-on-rails"] = actual_npm_version
    end

    File.write(file, "#{JSON.pretty_generate(content)}\n")
    puts "  Updated #{file}"
  end

  bundle_install_in(gem_root)
  # Update dummy app's Gemfile.lock
  bundle_install_in(dummy_app_dir)
  # Update pro dummy app's Gemfile.lock
  pro_dummy_app_dir = File.join(gem_root, "react_on_rails_pro", "spec", "dummy")
  bundle_install_in(pro_dummy_app_dir) if Dir.exist?(pro_dummy_app_dir)
  # Update pro root Gemfile.lock
  bundle_install_in(pro_gem_root)

  # Prepare NPM registry configuration
  npm_registry_url = use_verdaccio ? "http://localhost:4873/" : "https://registry.npmjs.org/"
  npm_publish_args = use_verdaccio ? "--registry #{npm_registry_url}" : ""

  if use_verdaccio
    puts "\n#{'=' * 80}"
    puts "VERDACCIO LOCAL REGISTRY MODE"
    puts "=" * 80
    puts "\nBefore proceeding, ensure:"
    puts "  1. Verdaccio server is running on http://localhost:4873/"
    puts "  2. You are authenticated with Verdaccio:"
    puts "     npm adduser --registry http://localhost:4873/"
    puts "\nPress ENTER to continue or Ctrl+C to cancel..."
    $stdin.gets unless is_dry_run
  end

  unless is_dry_run
    # Commit all version changes
    sh_in_dir(gem_root, "git add -A")
    sh_in_dir(gem_root, "git commit -m 'Bump version to #{actual_gem_version}'")

    # Create git tag
    sh_in_dir(gem_root, "git tag v#{actual_gem_version}")

    # Push commits and tags
    unless skip_push
      sh_in_dir(gem_root, "git push")
      sh_in_dir(gem_root, "git push --tags")
    end

    puts "\n#{'=' * 80}"
    puts "Publishing PUBLIC packages to #{use_verdaccio ? 'Verdaccio (local)' : 'npmjs.org'}..."
    puts "=" * 80

    # Publish react-on-rails NPM package
    puts "\nPublishing react-on-rails@#{actual_npm_version}..."
    puts "Carefully add your OTP for NPM when prompted." unless use_verdaccio
    sh_in_dir(gem_root, "yarn workspace react-on-rails publish --new-version #{actual_npm_version} #{npm_publish_args}")

    # Publish react-on-rails-pro NPM package
    puts "\nPublishing react-on-rails-pro@#{actual_npm_version}..."
    puts "Carefully add your OTP for NPM when prompted." unless use_verdaccio
    sh_in_dir(gem_root,
              "yarn workspace react-on-rails-pro publish --new-version #{actual_npm_version} #{npm_publish_args}")

    # Publish node-renderer NPM package (PUBLIC on npmjs.org)
    puts "\n#{'=' * 80}"
    puts "Publishing PUBLIC node-renderer to #{use_verdaccio ? 'Verdaccio (local)' : 'npmjs.org'}..."
    puts "=" * 80

    # Publish react-on-rails-pro-node-renderer NPM package
    # Note: Uses plain `yarn publish` (not `yarn workspace`) because the node-renderer
    # package.json is in react_on_rails_pro/ which is not defined as a workspace
    node_renderer_name = "react-on-rails-pro-node-renderer"
    puts "\nPublishing #{node_renderer_name}@#{actual_npm_version}..."
    puts "Carefully add your OTP for NPM when prompted." unless use_verdaccio
    sh_in_dir(pro_gem_root,
              "yarn publish --new-version #{actual_npm_version} --no-git-tag-version #{npm_publish_args}")

    if use_verdaccio
      puts "\nSkipping Ruby gem publication (Verdaccio is NPM-only)"
    else
      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC Ruby gem..."
      puts "=" * 80

      # Publish react_on_rails Ruby gem with retry logic
      ReleaseHelpers.publish_gem_with_retry(gem_root, "react_on_rails")

      # Add delay before next OTP operation to ensure clean separation
      puts "\n⏳ Waiting 5 seconds before next publication to ensure OTP separation..."
      sleep 5

      puts "\n#{'=' * 80}"
      puts "Publishing PUBLIC Pro Ruby gem to RubyGems.org..."
      puts "=" * 80

      # Publish react_on_rails_pro Ruby gem to RubyGems.org with retry logic
      puts "\nPublishing react_on_rails_pro gem to RubyGems.org..."
      puts "NOTE: Generate a FRESH OTP code (different from the previous one)."
      ReleaseHelpers.publish_gem_with_retry(pro_gem_root, "react_on_rails_pro")
    end
  end

  npm_registry_note = if use_verdaccio
                        "Verdaccio (http://localhost:4873/)"
                      else
                        "npmjs.org"
                      end

  if is_dry_run
    puts "\n#{'=' * 80}"
    puts "DRY RUN COMPLETE"
    puts "=" * 80
    puts "Version would be bumped to: #{actual_gem_version} (gem) / #{actual_npm_version} (npm)"
    puts "NPM Registry: #{npm_registry_note}"
    puts "\nFiles that would be updated:"
    puts "  - lib/react_on_rails/version.rb"
    puts "  - react_on_rails_pro/lib/react_on_rails_pro/version.rb"
    puts "  - package.json (root)"
    puts "  - packages/react-on-rails/package.json"
    puts "  - packages/react-on-rails-pro/package.json (version + dependency)"
    puts "  - react_on_rails_pro/package.json (node-renderer)"
    puts "  - Gemfile.lock files (root, dummy apps, pro)"
    puts "\nAuto-synced (no write needed):"
    puts "  - react_on_rails_pro/react_on_rails_pro.gemspec (uses ReactOnRails::VERSION)"
    registry_arg = use_verdaccio ? ",false,verdaccio" : ""
    puts "\nTo actually release, run: rake release[#{actual_gem_version}#{registry_arg}]"
  else
    msg = <<~MSG

      #{'=' * 80}
      RELEASE COMPLETE! 🎉
      #{'=' * 80}

      Published to #{npm_registry_note}:
        - react-on-rails@#{actual_npm_version}
        - react-on-rails-pro@#{actual_npm_version}
        - react-on-rails-pro-node-renderer@#{actual_npm_version}
    MSG

    unless use_verdaccio
      msg += "\n  Ruby Gems (RubyGems.org):\n"
      msg += "    - react_on_rails #{actual_gem_version}\n"
      msg += "    - react_on_rails_pro #{actual_gem_version}\n"
    end

    if skip_push
      msg += <<~SKIP_PUSH

        ⚠️  Git push was skipped. Don't forget to push manually:
          git push
          git push --tags

      SKIP_PUSH
    end

    msg += if use_verdaccio
             <<~VERDACCIO

               Verdaccio test packages published successfully!

               To test installation:
                 npm install --registry http://localhost:4873/ react-on-rails@#{actual_npm_version}
                 npm install --registry http://localhost:4873/ react-on-rails-pro@#{actual_npm_version}
                 npm install --registry http://localhost:4873/ react-on-rails-pro-node-renderer@#{actual_npm_version}

               Note: Ruby gems were not published (Verdaccio is NPM-only)

             VERDACCIO
           else
             <<~PRODUCTION

               Next steps:
                 1. Update CHANGELOG.md: bundle exec rake update_changelog
                 2. Update pro CHANGELOG.md: cd react_on_rails_pro && bundle exec rake update_changelog
                 3. Commit CHANGELOGs: git commit -a -m 'Update CHANGELOG.md files'
                 4. Push changes: git push

             PRODUCTION
           end

    puts msg
  end
end
# rubocop:enable Metrics/BlockLength
