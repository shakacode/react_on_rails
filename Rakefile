require "fileutils"

namespace :run_rspec do
  desc "Run RSpec for top level only"
  task :gem do
    sh %( rspec --exclude-pattern "spec/dummy/**/*_spec.rb" spec )
  end

  desc "Run RSpec for spec/dummy only"
  task :dummy do
    sh %( cd spec/dummy && rspec )
  end

  task run_rspec: [:gem, :dummy] do
    puts "Completed all RSpec tests"
  end
end
desc "Runs all tests. Run `rake -D run_rspec` to see all available test options"
task run_rspec: ["run_rspec:run_rspec"]

task default: :run_rspec

namespace :lint do
  desc "Run Rubocop as shell"
  task :rubocop do
    sh "rubocop ."
  end

  desc "Run ruby-lint as shell"
  task :ruby do
    sh "ruby-lint app spec lib"
  end

  desc "Run scss-lint as shell"
  task :scss do
    sh "scss-lint ."
  end

  desc "Run eslint as shell"
  task :eslint do
    sh "eslint . --ext .jsx and .js"
  end

  desc "Run jscs from shell"
  task :jscs do
    sh "jscs ."
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
    sh "docker-compose run lint rake lint:rubocop"
  end

  desc "Run ruby-lint linter from docker"
  task :ruby do
    sh "docker-compose run lint rake lint:ruby"
  end

  desc "Run scss-lint linter from docker"
  task :scss do
    sh "docker-compose run lint rake lint:scss"
  end

  desc "Run eslint linter from docker"
  task :eslint do
    sh "docker-compose run lint rake lint:eslint"
  end

  desc "Run jscs linter from docker"
  task :jscs do
    sh "docker-compose run lint rake lint:jscs"
  end
  desc "Run all linting from docker"
  task :lint do
    sh "docker-compose run lint rake lint"
  end
end

desc "Runs all linters from docker. Run `rake -D docker` to see all available lint options"
task docker: ["docker:lint"]
