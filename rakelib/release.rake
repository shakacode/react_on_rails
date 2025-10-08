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

# rubocop:disable Metrics/BlockLength

desc("Releases the gem and both NPM packages (react-on-rails and react-on-rails-pro).

IMPORTANT: the gem version must be in valid rubygem format (no dashes).
It will be automatically converted to valid npm semver by the rake task
for the node package versions. This only makes a difference for pre-release
versions such as `3.0.0.beta.1` (npm version would be `3.0.0-beta.1`).

This task depends on the gem-release ruby gem which is installed via `bundle install`.

1st argument: The new version in rubygem format (no dashes). Pass no argument to
              automatically perform a patch version bump.
2nd argument: Perform a dry run by passing 'true' as a second argument.
3rd argument: Use Verdaccio local registry by passing 'verdaccio' as a third argument.
              Requires Verdaccio server running on http://localhost:4873/
4th argument: Skip pushing to remote by passing 'skip_push' as a fourth argument.
              Useful for testing the release process locally.

Examples:
  rake release[16.2.0]                          # Release to production
  rake release[16.2.0,true]                     # Dry run
  rake release[16.2.0,false,verdaccio]          # Test release to Verdaccio
  rake release[16.2.0,false,npm,skip_push]      # Release without pushing to remote")
task :release, %i[gem_version dry_run registry skip_push] do |_t, args|
  include ReactOnRails::TaskHelpers

  # Check if there are uncommitted changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)
  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])
  use_verdaccio = args_hash.fetch(:registry, "") == "verdaccio"
  skip_push = args_hash.fetch(:skip_push, "") == "skip_push"

  gem_version = args_hash.fetch(:gem_version, "")

  # Having the examples prevents publishing
  Rake::Task["shakapacker_examples:clobber"].invoke
  # Delete any react_on_rails.gemspec except the root one
  sh_in_dir(gem_root, "find . -mindepth 2 -name 'react_on_rails.gemspec' -delete")

  # Pull latest changes
  sh_in_dir(gem_root, "git pull --rebase")

  # Bump gem version using gem-release
  sh_in_dir(gem_root, "gem bump --no-commit #{%(--version #{gem_version}) unless gem_version.strip.empty?}")

  # Read the actual version that was set
  actual_gem_version = begin
    version_file = File.join(gem_root, "lib", "react_on_rails", "version.rb")
    version_content = File.read(version_file)
    version_content.match(/VERSION = "(.+)"/)[1]
  end

  actual_npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(actual_gem_version)

  puts "Updating package.json files to version #{actual_npm_version}..."

  # Update all package.json files
  package_json_files = [
    File.join(gem_root, "package.json"),
    File.join(gem_root, "packages", "react-on-rails", "package.json"),
    File.join(gem_root, "packages", "react-on-rails-pro", "package.json")
  ]

  package_json_files.each do |file|
    content = JSON.parse(File.read(file))
    content["version"] = actual_npm_version

    # For react-on-rails-pro, also update the react-on-rails dependency
    if file.include?("react-on-rails-pro")
      content["dependencies"] ||= {}
      content["dependencies"]["react-on-rails"] = actual_npm_version
    end

    File.write(file, "#{JSON.pretty_generate(content)}\n")
    puts "  Updated #{file}"
  end

  # Update dummy app's Gemfile.lock
  bundle_install_in(dummy_app_dir)

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
    puts "Publishing NPM packages to #{use_verdaccio ? 'Verdaccio (local)' : 'npmjs.org'}..."
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

    if use_verdaccio
      puts "Skipping Ruby gem publication (Verdaccio mode)"
      puts "=" * 80
    else
      puts "\n#{'=' * 80}"
      puts "Publishing Ruby gem..."
      puts "=" * 80

      # Publish Ruby gem
      puts "\nCarefully add your OTP for Rubygems when prompted."
      sh_in_dir(gem_root, "gem release")
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
    puts "Files that would be updated:"
    puts "  - lib/react_on_rails/version.rb"
    puts "  - package.json (root)"
    puts "  - packages/react-on-rails/package.json"
    puts "  - packages/react-on-rails-pro/package.json (version + dependency)"
    puts "  - spec/dummy/Gemfile.lock"
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
    MSG

    msg += "    - react_on_rails #{actual_gem_version} (RubyGems)\n" unless use_verdaccio

    if skip_push
      msg += <<~SKIP_PUSH

        ⚠️  Git push was skipped. Don't forget to push manually:
          git push
          git push --tags

      SKIP_PUSH
    end

    if use_verdaccio
      msg += <<~VERDACCIO

        Verdaccio test packages published successfully!

        To test installation:
          npm install --registry http://localhost:4873/ react-on-rails@#{actual_npm_version}
          npm install --registry http://localhost:4873/ react-on-rails-pro@#{actual_npm_version}

      VERDACCIO
    else
      msg += <<~PRODUCTION

        Next steps:
          1. Update CHANGELOG.md: bundle exec rake update_changelog
          3. Commit CHANGELOG: cd #{gem_root} && git commit -a -m 'Update CHANGELOG.md and spec/dummy Gemfile.lock'
          4. Push changes: git push

      PRODUCTION
    end

    puts msg
  end
end
# rubocop:enable Metrics/BlockLength
