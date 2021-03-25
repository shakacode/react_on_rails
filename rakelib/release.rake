# frozen_string_literal: true

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

desc("Releases both the gem and node package using the given version.

IMPORTANT: the gem version must be in valid rubygem format (no dashes).
It will be automatically converted to a valid yarn semver by the rake task
for the node package version. This only makes a difference for pre-release
versions such as `3.0.0.beta.1` (yarn version would be `3.0.0-beta.1`).

This task depends on the gem-release (ruby gem) and release-it (node package)
which are installed via `bundle install` and `yarn global add release-it`

1st argument: The new version in rubygem format (no dashes). Pass no argument to
              automatically perform a patch version bump.
2nd argument: Perform a dry run by passing 'true' as a second argument.

Example: `rake release[2.1.0,false]`")
task :release, %i[gem_version dry_run tools_install] do |_t, args|
  include ReactOnRails::TaskHelpers

  # Check if there are uncommited changes
  ReactOnRails::GitUtils.uncommitted_changes?(RaisingMessageHandler.new)
  args_hash = args.to_hash

  is_dry_run = ReactOnRails::Utils.object_to_boolean(args_hash[:dry_run])

  gem_version = args_hash.fetch(:gem_version, "")

  npm_version = if gem_version.strip.empty?
                  ""
                else
                  ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(gem_version)
                end

  # Having the examples prevents publishing
  Rake::Task["examples:clobber"].invoke
  # Delete any react_on_rails.gemspec except the root one
  sh_in_dir(gem_root, "find . -mindepth 2 -name 'react_on_rails.gemspec' -delete")

  # See https://github.com/svenfuchs/gem-release
  sh_in_dir(gem_root, "git pull --rebase")
  sh_in_dir(gem_root, "gem bump --no-commit #{gem_version.strip.empty? ? '' : %(--version #{gem_version})}")

  # Update dummy app's Gemfile.lock
  bundle_install_in(dummy_app_dir)

  # Will bump the yarn version, commit, tag the commit, push to repo, and release on yarn
  release_it_command = +"release-it"
  release_it_command << " #{npm_version}" unless npm_version.strip.empty?
  release_it_command << " --ci --npm.publish --no-git.requireCleanWorkingDir"
  release_it_command << " --dry-run --verbose" if is_dry_run
  sh_in_dir(gem_root, release_it_command)

  # Release the new gem version
  sh_in_dir(gem_root, "gem release") unless is_dry_run

  msg = <<~MSG
    Once you have successfully published, run these commands to update the spec apps:

    cd #{dummy_app_dir}; bundle update react_on_rails
    cd #{gem_root}#{' '}
    git commit -a -m 'Update Gemfile.lock for spec app'
    git push
  MSG
  puts msg
end
# rubocop:enable Metrics/BlockLength

task :test do
  unbundled_sh_in_dir(gem_root, "cd #{dummy_app_dir}; bundle update react_on_rails")
  sh_in_dir(gem_root, "git commit -a -m 'Update Gemfile.lock for spec app'")
  sh_in_dir(gem_root, "git push")
end
