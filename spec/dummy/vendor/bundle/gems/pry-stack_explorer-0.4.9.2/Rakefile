$:.unshift 'lib'

dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-stack_explorer"

require 'rake/clean'
require 'rubygems/package_task'
require "#{PROJECT_NAME}/version"

CLOBBER.include("**/*~", "**/*#*", "**/*.log")
CLEAN.include("**/*#*", "**/*#*.*", "**/*_flymake*.*", "**/*_flymake",
              "**/*.rbc", "**/.#*.*")

def apply_spec_defaults(s)
  s.name = PROJECT_NAME
  s.summary = "Walk the stack in a Pry session"
  s.version = PryStackExplorer::VERSION
  s.date = Time.now.strftime '%Y-%m-%d'
  s.author = "John Mair (banisterfiend)"
  s.email = 'jrmair@gmail.com'
  s.description = s.summary
  s.require_path = 'lib'
  s.add_dependency("binding_of_caller",">= 0.7")
  s.add_dependency("pry",">=0.9.11")
  s.add_development_dependency("bacon","~>1.1.0")
  s.add_development_dependency('rake', '~> 0.9')
  s.homepage = "https://github.com/pry/pry-stack_explorer"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
end

desc "run pry with plugin enabled"
task :pry do
  exec("pry -rubygems -I#{direc}/lib/ -r #{direc}/lib/#{PROJECT_NAME}")
end

desc "Run example"
task :example do
  sh "ruby -rubygems -I#{direc}/lib/ #{direc}/examples/example.rb "
end

desc "Run example2"
task :example2 do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example2.rb "
end

desc "Run example3"
task :example3 do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example3.rb "
end

desc "Show version"
task :version do
  puts "PryStackExplorer version: #{PryStackExplorer::VERSION}"
end

desc "run tests"
task :default => :test

desc "run tests"
task :test do
  sh "bacon -Itest -rubygems -a -q"
end

desc "generate gemspec"
task :gemspec => "ruby:gemspec"

namespace :ruby do
  spec = Gem::Specification.new do |s|
    apply_spec_defaults(s)
    s.platform = Gem::Platform::RUBY
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end

  desc  "Generate gemspec file"
  task :gemspec do
    File.open("#{spec.name}.gemspec", "w") do |f|
      f << spec.to_ruby
    end
  end
end

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, :gemspec, "ruby:gem"]

desc "remove all platform gems"
task :rmgems => ["ruby:clobber_package"]

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall pry-stack_explorer" rescue nil
  sh "gem install -l #{direc}/pkg/#{PROJECT_NAME}-#{PryStackExplorer::VERSION}.gem"
end

task :install => :reinstall

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{File.dirname(__FILE__)}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end

task :pushgem => :pushgems
