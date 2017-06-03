# frozen_string_literal: true

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

  desc "Run all linting from docker"
  task :lint do
    sh "docker-compose run lint rake lint"
  end
end

desc "Runs all linters from docker. Run `rake -D docker` to see all available lint options"
task docker: ["docker:lint"]
