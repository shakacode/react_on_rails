# frozen_string_literal: true

require_relative "task_helpers"

namespace :lint do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop --version", "bundle exec rubocop .")
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
    sh_in_dir(gem_root, "bundle exec rubocop -A")
    puts "Completed auto-fixing all linting violations"
  end

  private

  def stylelint_command
    "pnpm run stylelint \"spec/dummy/app/assets/stylesheets/**/*.scss\" \"spec/dummy/client/**/*.scss\""
  end

  def stylelint_fix_command
    "#{stylelint_command} --fix"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]

desc "Auto-fix all linting violations (eslint --fix, prettier --write, rubocop -A)"
task autofix: ["lint:autofix"]
