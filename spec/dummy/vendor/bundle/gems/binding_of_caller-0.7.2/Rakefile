dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

$:.unshift 'lib'

require 'rake/clean'
require 'rubygems/package_task'

require "binding_of_caller/version"

CLOBBER.include("**/*.#{dlext}", "**/*~", "**/*#*", "**/*.log", "**/*.o")
CLEAN.include("ext/**/*.#{dlext}", "ext/**/*.log", "ext/**/*.o",
              "ext/**/*~", "ext/**/*#*", "ext/**/*.obj", "**/*#*", "**/*#*.*",
              "ext/**/*.def", "ext/**/*.pdb", "**/*_flymake*.*", "**/*_flymake", "**/*.rbc")

def mri_2?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" &&
    RUBY_VERSION =~ /^2/
end

def apply_spec_defaults(s)
  s.name = "binding_of_caller"
  s.summary = "Retrieve the binding of a method's caller. Can also retrieve bindings even further up the stack."
  s.version = BindingOfCaller::VERSION
  s.date = Time.now.strftime '%Y-%m-%d'
  s.author = "John Mair (banisterfiend)"
  s.email = 'jrmair@gmail.com'
  s.description = s.summary
  s.require_path = 'lib'
  s.add_dependency 'debug_inspector', '>= 0.0.1'
  s.add_development_dependency 'bacon'
  s.add_development_dependency 'rake'
  s.homepage = "http://github.com/banister/binding_of_caller"
  s.has_rdoc = 'yard'
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
end

desc "Show version"
task :version do
  puts "BindingOfCaller version: #{BindingOfCaller::VERSION}"
end

desc "run tests"
task :default => [:test]

desc "Run tests"
task :test do
  unless defined?(Rubinius)
    Rake::Task['compile'].execute
  end

  $stdout.puts("\033[33m")
  sh "bacon -Itest -rubygems -a -q"
  $stdout.puts("\033[0m")

  unless defined?(Rubinius)
    Rake::Task['cleanup'].execute
  end
end

task :pry do
  puts "loading binding_of_caller into pry"
  sh "pry -r ./lib/binding_of_caller"
end

desc "generate gemspec"
task :gemspec => "ruby:gemspec"

namespace :ruby do
  spec = Gem::Specification.new do |s|
    apply_spec_defaults(s)
    s.platform = Gem::Platform::RUBY
    s.extensions = ["ext/binding_of_caller/extconf.rb"]
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

desc "build the binaries"
task :compile => :cleanup do
  if !mri_2?  
    chdir "./ext/binding_of_caller/" do
      sh "ruby extconf.rb"
      sh "make"
      sh "cp *.#{dlext} ../../lib/"
    end
  end
end

desc 'cleanup the extensions'
task :cleanup do
  if !mri_2?
    sh 'rm -rf lib/binding_of_caller.so'
    chdir "./ext/binding_of_caller/" do
      sh 'make clean' 
    end
  end
end

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall binding_of_caller" rescue nil
  sh "gem install #{direc}/pkg/binding_of_caller-#{BindingOfCaller::VERSION}.gem"
end

task :install => :reinstall

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, "ruby:gem"]

task :gem => [:gems]

desc "remove all platform gems"
task :rmgems => ["ruby:clobber_package"]

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("./pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end
