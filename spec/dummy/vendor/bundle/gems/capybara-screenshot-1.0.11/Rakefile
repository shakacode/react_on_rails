require 'rubygems'
require 'bundler/setup'

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

rspec_rake_task = RSpec::Core::RakeTask.new(:spec)

task default: [:spec]

def target_gem
  gem_file = ENV['BUNDLE_GEMFILE'] || ''
  targets = %w(cucumber spinach rspec)

  target = gem_file.match(/(#{targets.join('|')})/)
  if target && targets.include?(target[1])
    target[1].to_sym
  else
    []
  end
end

namespace :travis do
  task :ci => target_gem do
    Rake::Task['spec'].invoke
  end

  task :cucumber do
    rspec_rake_task.pattern = 'spec/cucumber'
  end

  task :spinach do
    rspec_rake_task.pattern = 'spec/spinach'
  end

  task :rspec do
    rspec_rake_task.pattern = 'spec/rspec'
  end
end
