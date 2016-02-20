
require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :spec

require 'rake/testtask'
Rake::TestTask.new(:spec) do |test|
  test.libs << '.'
  test.ruby_opts = ['-rubygems']
  test.pattern = 'spec/*_spec.rb'
  test.verbose = true
end
