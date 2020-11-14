# frozen_string_literal: true

require_relative "task_helpers"

namespace :lint do
  include ReactOnRails::TaskHelpers

  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop --version", "bundle exec rubocop .")
  end

  desc "Run scss-lint as shell"
  task :scss do
    sh_in_dir(gem_root, "bundle exec scss-lint spec/dummy/app/assets/stylesheets/")
  end

  desc "Run eslint as shell"
  task :eslint do
    sh_in_dir(gem_root, "yarn run eslint --version", "yarn run eslint .")
  end

  desc "Run all eslint & rubocop linters. Skip scss"
  task lint: %i[eslint rubocop] do
    puts "Completed all linting"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]
