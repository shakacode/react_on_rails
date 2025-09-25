# frozen_string_literal: true

require_relative "task_helpers"

namespace :lint do
  include ReactOnRails::TaskHelpers

  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop --version", "bundle exec rubocop .")
  end

  desc "Run stylelint as shell"
  task :scss do
    sh_in_dir(gem_root, "yarn run stylelint \"spec/dummy/app/assets/stylesheets/**/*.scss\" \"spec/dummy/client/**/*.scss\"")
  end

  desc "Run eslint as shell"
  task :eslint do
    sh_in_dir(gem_root, "yarn run eslint --version", "yarn run eslint .")
  end

  desc "Run all eslint, rubocop & stylelint linters"
  task lint: %i[eslint rubocop scss] do
    puts "Completed all linting"
  end

  desc "Auto-fix all linting violations"
  task :autofix do
    sh_in_dir(gem_root, "yarn run eslint . --fix")
    sh_in_dir(gem_root, "yarn run prettier --write .")
    sh_in_dir(gem_root, "yarn run stylelint \"spec/dummy/app/assets/stylesheets/**/*.scss\" \"spec/dummy/client/**/*.scss\" --fix")
    sh_in_dir(gem_root, "bundle exec rubocop -A")
    puts "Completed auto-fixing all linting violations"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]

desc "Auto-fix all linting violations (eslint --fix, prettier --write, rubocop -A)"
task autofix: ["lint:autofix"]
