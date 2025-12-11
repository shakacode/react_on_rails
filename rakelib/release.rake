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

# Helper methods for release-specific tasks
# These are defined at the top level so they have access to Rake's sh method

def verify_npm_auth(registry_url = "https://registry.npmjs.org/")
  result = `npm whoami --registry #{registry_url} 2>&1`
  unless $CHILD_STATUS.success?
    puts <<~MESSAGE
      ⚠️  NPM authentication required!

      You are not logged in to NPM. Running 'npm login' now...

    MESSAGE

    # Run npm login interactively
    system("npm login --registry #{registry_url}")

    # Verify login succeeded
    result = `npm whoami --registry #{registry_url} 2>&1`
    unless $CHILD_STATUS.success?
      abort <<~ERROR
        ❌ NPM login failed!

        Please manually run 'npm login' and retry the release.

        Technical details:
          Registry: #{registry_url}
          Error: #{result.strip}
      ERROR
    end
  end
  puts "✓ Logged in to NPM as: #{result.strip}"
end

def publish_gem_with_retry(dir, gem_name, otp: nil, max_retries: ENV.fetch("GEM_RELEASE_MAX_RETRIES", "3").to_i)
  puts "\nPublishing #{gem_name} gem to RubyGems.org..."
  if otp
    puts "Using provided OTP code..."
  else
    puts "Carefully add your OTP for Rubygems when prompted."
    puts "NOTE: OTP codes expire quickly (typically 30 seconds). Generate a fresh code when prompted."
  end

  retry_count = 0
  success = false

  while retry_count < max_retries && !success
    begin
      otp_flag = otp ? "--otp #{otp}" : ""
      sh %(cd #{dir} && gem release #{otp_flag})
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

# rubocop:disable Metrics/BlockLength

desc("Unified release script for all React on Rails packages and gems.

IMPORTANT: This script uses UNIFIED VERSIONING - all packages (core + pro) will be
updated to the same version number and released together.

Version argument can be:
  - Semver bump type: 'patch', 'minor', or 'major' (e.g., 16.1.1 → 16.1.2, 16.2.0, or 17.0.0)
  - Explicit version: '16.2.0'
  - Pre-release version: '16.2.0.beta.1' (rubygem format with dots, converted to 16.2.0-beta.1 for NPM)

Note: Pre-release versions (containing .test., .beta., .alpha., .rc., or .pre.) automatically
skip git branch checks, allowing releases from non-master branches.

This will update and release:
  PUBLIC (npmjs.org + rubygems.org):
    - react-on-rails NPM package
    - react-on-rails-pro NPM package
    - react-on-rails-pro-node-renderer NPM package
    - react_on_rails RubyGem
    - react_on_rails_pro RubyGem

1st argument: Version (patch/minor/major OR explicit version like 16.2.0)
2nd argument: Dry run (true/false, default: false)

Environment variables:
  VERBOSE=1                    # Enable verbose logging (shows all output)
  NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
  RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
  GEM_RELEASE_MAX_RETRIES=<n>  # Override max retry attempts (default: 3)

Examples:
  rake release[patch]                           # Bump patch version (16.1.1 → 16.1.2)
  rake release[minor]                           # Bump minor version (16.1.1 → 16.2.0)
  rake release[major]                           # Bump major version (16.1.1 → 17.0.0)
  rake release[16.2.0]                          # Set explicit version
  rake release[16.2.0.beta.1]                   # Set pre-release version (→ 16.2.0-beta.1 for NPM)
  rake release[patch,true]                      # Dry run
  VERBOSE=1 rake release[patch]                 # Release with verbose logging
  NPM_OTP=123456 RUBYGEMS_OTP=789012 rake release[patch]  # Skip OTP prompts")
task :release, %i[version dry_run] do |_t, args|
  include ReactOnRails::TaskHelpers

  # Check if there are uncommitted changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)
  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])
  is_verbose = ENV["VERBOSE"] == "1"
  npm_otp = ENV.fetch("NPM_OTP", nil)
  rubygems_otp = ENV.fetch("RUBYGEMS_OTP", nil)

  # Configure output verbosity
  verbose(is_verbose)

  # Detect if this is a test/pre-release version (contains test, beta, alpha, rc, etc.)
  version_input = args_hash.fetch(:version, "")
  is_prerelease = version_input.match?(/\.(test|beta|alpha|rc|pre)\./i)

  if version_input.strip.empty?
    raise ArgumentError,
          "Version argument is required. Use 'patch', 'minor', 'major', or explicit version (e.g., '16.2.0')"
  end

  # Pre-flight authentication checks (skip for dry runs)
  unless is_dry_run
    puts "\n#{'=' * 80}"
    puts "PRE-FLIGHT CHECKS"
    puts "=" * 80
    verify_npm_auth
  end

  # Having the examples prevents publishing
  Rake::Task["shakapacker_examples:clobber"].invoke
  # Delete any react_on_rails.gemspec except the root one
  sh_in_dir(gem_root, "find . -mindepth 2 -name 'react_on_rails.gemspec' -delete")
  # Delete any react_on_rails_pro.gemspec except the one in react_on_rails_pro directory
  sh_in_dir(gem_root, "find . -mindepth 3 -name 'react_on_rails_pro.gemspec' -delete")

  # Pull latest changes (skip in dry-run mode)
  sh_in_dir(monorepo_root, "git pull --rebase") unless is_dry_run

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

  # Update all package.json files (only publishable packages)
  package_json_files = [
    File.join(monorepo_root, "package.json"),
    File.join(monorepo_root, "packages", "react-on-rails", "package.json"),
    File.join(monorepo_root, "packages", "react-on-rails-pro", "package.json"),
    File.join(monorepo_root, "packages", "react-on-rails-pro-node-renderer", "package.json")
  ]

  package_json_files.each do |file|
    content = JSON.parse(File.read(file))
    content["version"] = actual_npm_version
    # NOTE: workspace:* dependencies (e.g., in react-on-rails-pro) are automatically
    # converted to exact versions by pnpm during publish. No manual conversion needed.

    File.write(file, "#{JSON.pretty_generate(content)}\n")
    puts "  Updated #{file}"
  end

  puts "\nUpdating Gemfile.lock files..."
  bundle_quiet_flag = is_verbose ? "" : " --quiet"

  # Update all Gemfile.lock files
  unbundled_sh_in_dir(gem_root, "bundle install#{bundle_quiet_flag}")
  unbundled_sh_in_dir(dummy_app_dir, "bundle install#{bundle_quiet_flag}")
  unbundled_sh_in_dir(pro_dummy_app_dir, "bundle install#{bundle_quiet_flag}") if Dir.exist?(pro_dummy_app_dir)
  unbundled_sh_in_dir(pro_gem_root, "bundle install#{bundle_quiet_flag}")

  # Prepare NPM publish args
  npm_publish_args = ""

  unless is_dry_run
    # Commit all version changes (skip git hooks to save time)
    sh_in_dir(monorepo_root, "LEFTHOOK=0 git add -A")

    # Only commit if there are staged changes (version might already be set)
    git_status = `cd #{monorepo_root} && git diff --cached --quiet; echo $?`.strip
    if git_status == "0"
      puts "No version changes to commit (version already set to #{actual_gem_version})"
    else
      sh_in_dir(monorepo_root, "LEFTHOOK=0 git commit -m 'Bump version to #{actual_gem_version}'")
    end

    # Create git tag (skip if it already exists)
    tag_name = "v#{actual_gem_version}"
    tag_exists = system("cd #{monorepo_root} && git rev-parse #{tag_name} >/dev/null 2>&1")
    if tag_exists
      puts "Git tag #{tag_name} already exists, skipping tag creation"
    else
      sh_in_dir(monorepo_root, "git tag #{tag_name}")
    end

    # Push commits and tags (skip git hooks)
    sh_in_dir(monorepo_root, "LEFTHOOK=0 git push")
    sh_in_dir(monorepo_root, "LEFTHOOK=0 git push --tags")

    puts "\n#{'=' * 80}"
    puts "Publishing PUBLIC packages to npmjs.org..."
    puts "=" * 80

    # Configure NPM OTP
    if npm_otp
      npm_publish_args += " --otp #{npm_otp}"
      puts "Using provided NPM OTP for all NPM package publications..."
    else
      puts "\nNOTE: You will be prompted for NPM OTP code for each of the 3 NPM packages."
      puts "TIP: Set NPM_OTP environment variable to avoid repeated prompts."
    end

    # For pre-release versions, skip git branch checks (allows releasing from non-master branches)
    if is_prerelease
      npm_publish_args += " --no-git-checks"
      puts "Pre-release version detected - skipping git branch checks for NPM publish"
    end

    # Publish react-on-rails NPM package
    puts "\nPublishing react-on-rails@#{actual_npm_version}..."
    sh_in_dir(File.join(monorepo_root, "packages", "react-on-rails"), "pnpm publish #{npm_publish_args}")

    # Publish react-on-rails-pro NPM package
    puts "\nPublishing react-on-rails-pro@#{actual_npm_version}..."
    sh_in_dir(File.join(monorepo_root, "packages", "react-on-rails-pro"), "pnpm publish #{npm_publish_args}")

    # Publish node-renderer NPM package (PUBLIC on npmjs.org)
    puts "\n#{'=' * 80}"
    puts "Publishing PUBLIC node-renderer to npmjs.org..."
    puts "=" * 80

    # Publish react-on-rails-pro-node-renderer NPM package
    node_renderer_name = "react-on-rails-pro-node-renderer"
    node_renderer_dir = File.join(monorepo_root, "packages", "react-on-rails-pro-node-renderer")
    puts "\nPublishing #{node_renderer_name}@#{actual_npm_version}..."
    sh_in_dir(node_renderer_dir, "pnpm publish #{npm_publish_args}")

    puts "\n#{'=' * 80}"
    puts "Publishing PUBLIC Ruby gems..."
    puts "=" * 80

    if rubygems_otp
      puts "Using provided RubyGems OTP for both gem publications..."
    else
      puts "\nNOTE: You will be prompted for RubyGems OTP code for each of the 2 gems."
      puts "TIP: Set RUBYGEMS_OTP environment variable to avoid repeated prompts."
    end

    # Publish react_on_rails Ruby gem with retry logic
    publish_gem_with_retry(gem_root, "react_on_rails", otp: rubygems_otp)

    # Add delay before next OTP operation to ensure clean separation
    puts "\n⏳ Waiting 5 seconds before next publication to ensure OTP separation..."
    sleep 5

    # Publish react_on_rails_pro Ruby gem to RubyGems.org with retry logic
    publish_gem_with_retry(pro_gem_root, "react_on_rails_pro", otp: rubygems_otp)
  end

  if is_dry_run
    puts "\n#{'=' * 80}"
    puts "DRY RUN COMPLETE"
    puts "=" * 80
    puts "Version would be bumped to: #{actual_gem_version} (gem) / #{actual_npm_version} (npm)"
    puts "\nFiles that would be updated:"
    puts "  - react_on_rails/lib/react_on_rails/version.rb"
    puts "  - react_on_rails_pro/lib/react_on_rails_pro/version.rb"
    puts "  - package.json (root)"
    puts "  - packages/react-on-rails/package.json"
    puts "  - packages/react-on-rails-pro/package.json (version only; workspace:* converted by pnpm)"
    puts "  - packages/react-on-rails-pro-node-renderer/package.json"
    puts "  - Gemfile.lock files (root, dummy apps, pro)"
    puts "\nAuto-synced (no write needed):"
    puts "  - react_on_rails_pro/react_on_rails_pro.gemspec (uses ReactOnRails::VERSION)"
    puts "\nTo actually release, run: rake release[#{actual_gem_version}]"
  else
    msg = <<~MSG

      #{'=' * 80}
      RELEASE COMPLETE!
      #{'=' * 80}

      Published to npmjs.org:
        - react-on-rails@#{actual_npm_version}
        - react-on-rails-pro@#{actual_npm_version}
        - react-on-rails-pro-node-renderer@#{actual_npm_version}

      Ruby Gems (RubyGems.org):
        - react_on_rails #{actual_gem_version}
        - react_on_rails_pro #{actual_gem_version}

      Next steps:
        Option A - Use Claude Code:
          Run /update-changelog in Claude Code to update and create a PR

        Option B - Manual:
          1. Update CHANGELOG.md: bundle exec rake update_changelog
          2. Update pro CHANGELOG.md: cd react_on_rails_pro && bundle exec rake update_changelog
          3. Commit CHANGELOGs: git commit -a -m 'Update CHANGELOG.md files'
          4. Push changes: git push

    MSG

    puts msg
  end
end
# rubocop:enable Metrics/BlockLength
