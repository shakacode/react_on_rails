require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :lint do
  desc "Run Rubocop as shell"
  task :rubocop do
    sh_in_dir(gem_root, "bundle exec rubocop .")
  end

  desc "Run ruby-lint as shell"
  task :ruby do
    puts "See /ruby-lint.yml for what directories are included."
    sh_in_dir(gem_root, "bundle exec ruby-lint .")
  end

  desc "Run scss-lint as shell"
  task :scss do
    sh_in_dir(gem_root, "bundle exec scss-lint spec/dummy/app/assets/stylesheets/")
  end

  desc "Run eslint as shell"
  task :eslint do
    sh_in_dir(gem_root, "npm run eslint")
  end

  desc "Run jscs from shell"
  task :jscs do
    sh_in_dir(gem_root, "npm run jscs")
  end

  desc "Run flow from shell"
  task :flow do
    sh_in_dir(gem_root, "npm run flow")
  end

  desc "Run all eslint, jscs, flow, rubocop linters. Skip ruby-lint and scss"
  task lint: [:eslint, :jscs, :flow, :rubocop] do
    puts "Completed all linting"
  end
end

desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]
