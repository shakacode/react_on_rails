require "fileutils"
require "coveralls/rake/task"

namespace :run_rspec do
  desc "Run RSpec for top level only"
  task :gem do
    sh %( COVERAGE=true rspec spec/react_on_rails_spec.rb )
  end

  desc "Run RSpec for spec/dummy only"
  task :dummy do
    # TEST_ENV_NUMBER is used to make SimpleCov.command_name unique in order to
    # prevent a name collision
    sh %( cd spec/dummy && DRIVER=selenium_firefox COVERAGE=true TEST_ENV_NUMBER=1 rspec )
  end

  desc "Run RSpec for spec/dummy only"
  task :dummy_react_013 do
    # TEST_ENV_NUMBER is used to make SimpleCov.command_name unique in order to
    # prevent a name collision
    sh %( cd spec/dummy-react-013 && DRIVER=selenium_firefox COVERAGE=true TEST_ENV_NUMBER=2 rspec )
  end

  desc "Run RSpec on spec/empty_spec in order to have SimpleCov generate a coverage report from cache"
  task :empty do
    sh %( COVERAGE=true rspec spec/empty_spec.rb )
  end

  Coveralls::RakeTask.new

  task run_rspec: [:gem, :dummy, :dummy_react_013, :empty, "coveralls:push"] do
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
    sh "scss-lint spec/dummy/app/assets/stylesheets/"
  end

  desc "Run eslint as shell"
  task :eslint do
    sh "eslint . --ext .jsx and .js"
  end

  desc "Run jscs from shell"
  task :jscs do
    sh "jscs -e -v ."
  end

  desc "Run all eslint, jscs, rubocop linters. Skip ruby-lint and scss"
  task lint: [:eslint, :jscs, :rubocop, :scss] do
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

desc "Run all tests and linting"
task ci: %w(docker run_rspec)
