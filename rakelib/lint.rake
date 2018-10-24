# frozen_string_literal: true

require_relative "task_helpers"

namespace :lint do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop .")
  end

  desc "Run scss-lint as shell"
  task :scss do
    sh_in_dir(gem_root, "bundle exec scss-lint spec/dummy/app/assets/stylesheets/")
  end

  desc "Run linters and flow from shell"
  task :js_checks do
    sh_in_dir(gem_root, "yarn start check")
  end

  desc "Run all eslint, flow, rubocop linters. Skip ruby-lint and scss"
  task lint: %i[js_checks rubocop] do
    puts "Completed all linting"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]
