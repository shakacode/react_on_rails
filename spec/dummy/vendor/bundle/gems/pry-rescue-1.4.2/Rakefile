require 'rspec/core/rake_task'

task :default => :test
task :spec => :test

desc "Run example"
task :example do
  sh "ruby -I./lib/ ./examples/example.rb "
end

desc "Run example 2"
task :example2 do
  sh "ruby -I./lib/ ./examples/example2.rb "
end

desc 'Run syntax-err example'
task :sintax do
  ENV['RUBYLIB'] = 'lib'
  sh 'bin/rescue examples/syntax-err.rb'
end

RSpec::Core::RakeTask.new(:test)

task :build do
  sh 'gem build *.gemspec'
end

task :install => :build do
  sh 'gem install *.gem'
end
