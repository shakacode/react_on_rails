# frozen_string_literal: true

require_relative "task_helpers"

# rubocop:disable Style/MixinUsage
include ReactOnRailsPro::TaskHelpers
# rubocop:enable Style/MixinUsage

namespace :lint do
  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop .")
  end

  desc "Run eslint as shell"
  task :eslint do
    sh_in_dir(gem_root, "pnpm run eslint")
  end

  desc "Run all eslint, rubocop linters"
  task lint: %i[eslint rubocop] do
    puts "Completed all linting"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]
