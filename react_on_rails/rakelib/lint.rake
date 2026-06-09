# frozen_string_literal: true

require_relative "task_helpers"

namespace :lint do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  def root_bundle_command(command)
    root_gemfile = File.join(monorepo_root, "Gemfile")
    "BUNDLE_GEMFILE=\"#{root_gemfile}\" #{command}"
  end

  desc "Run Rubocop as shell"
  task :rubocop do
    Bundler.with_unbundled_env do
      sh_in_dir(
        gem_root,
        root_bundle_command("bundle exec rubocop --version"),
        root_bundle_command("bundle exec rubocop .")
      )
    end
  end

  desc "Run stylelint as shell"
  task :scss do
    sh_in_dir(gem_root, stylelint_command)
  end

  desc "Run eslint as shell"
  task :eslint do
    sh_in_dir(gem_root, "pnpm run eslint --version", "pnpm run eslint .")
  end

  desc "Run all eslint, rubocop & stylelint linters"
  task lint: %i[eslint rubocop scss] do
    puts "Completed all linting"
  end

  desc "Auto-fix all linting violations"
  task :autofix do
    sh_in_dir(gem_root, "pnpm run eslint . --fix")
    sh_in_dir(gem_root, "pnpm run prettier --write .")
    sh_in_dir(gem_root, stylelint_fix_command)
    Bundler.with_unbundled_env do
      sh_in_dir(gem_root, root_bundle_command("bundle exec rubocop -A"))
    end
    puts "Completed auto-fixing all linting violations"
  end

  private

  def stylelint_command
    "pnpm run lint:scss"
  end

  def stylelint_fix_command
    "#{stylelint_command} --fix"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]

desc "Auto-fix all linting violations (eslint --fix, prettier --write, rubocop -A)"
task autofix: ["lint:autofix"]
