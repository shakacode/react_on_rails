require "fileutils"

task :run_rspec do
  sh %{ rspec --exclude-pattern "spec/dummy/**/*_spec.rb" spec }
  sh %{ cd spec/dummy && rspec }
end

task :default => :run_rspec

namespace :lint do

  desc "Run Rubocop as shell"
  task :rubocop do
    cmd = "rubocop ."
    sh cmd
  end

  desc "Run ruby-lint as shell"
  task :ruby do
    cmd = "ruby-lint app spec lib"
    sh cmd
  end

  desc "Run scss-lint as shell"
  task :scss do
    cmd = "scss-lint ."
    sh cmd
  end

  desc "Run eslint as shell"
  task :eslint do
    cmd = "eslint . --ext .jsx and .js"
    sh cmd
  end

  desc "Run jscs from shell"
  task :jscs do
    cmd = "jscs ."
    sh cmd
  end

  task lint: [:eslint, :rubocop, :ruby, :jscs, :scss] do
    puts "Completed all linting"
  end
end
desc "Runs all linters. Run `rake -D lint` to see all available lint options"
task lint: ["lint:lint"]

namespace :docker do
  desc "Run Rubocop linter from docker"
  task :rubocop do
    cmd = "docker-compose run lint rake lint:rubocop"
    sh cmd
  end

  desc "Run ruby-lint linter from docker"
  task :ruby do
    cmd = "docker-compose run lint rake lint:ruby"
    sh cmd
  end

  desc "Run scss-lint linter from docker"
  task :scss do
    cmd = "docker-compose run lint rake lint:scss"
    sh cmd
  end

  desc "Run eslint linter from docker"
  task :eslint do
    cmd = "docker-compose run lint rake lint:eslint"
    sh cmd
  end

  desc "Run jscs linter from docker"
  task :jscs do
    cmd = "docker-compose run lint rake lint:jscs"
    sh cmd
  end
  desc "Run all linting from docker"
  task :lint do
    cmd = "docker-compose run lint rake lint"
    sh cmd
  end
end

desc "Runs all linters from docker. Run `rake -D docker` to see all available lint options"
task docker: ["docker:lint"]


