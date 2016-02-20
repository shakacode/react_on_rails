$:.unshift 'lib'
require 'rake/clean'
require "debug_inspector/version"

dlext = RbConfig::CONFIG['DLEXT']
direc = File.expand_path(File.dirname(__FILE__))
CLOBBER.include("**/*.#{dlext}", "**/*~", "**/*#*", "**/*.log", "**/*.o")
CLEAN.include("ext/**/*.#{dlext}", "ext/**/*.log", "ext/**/*.o",
              "ext/**/*~", "ext/**/*#*", "ext/**/*.obj", "**/*#*", "**/*#*.*",
              "ext/**/*.def", "ext/**/*.pdb", "**/*_flymake*.*", "**/*_flymake", "**/*.rbc")
desc "Show version"
task :version do
  puts "debug_inspector version: #{DebugInspector::VERSION}"
end

desc "run tests"
task :default => [:test]

desc "Run tests"
task :test do
  sh "bacon -Itest -rubygems -a -q"
end

task :pry do
  puts "loading debug_inspector into pry"
  sh "pry -r #{direc}/lib/debug_inspector"
end

desc "build the binaries"
task :compile do
  chdir "#{direc}/ext/debug_inspector/" do
    sh "ruby extconf.rb"
    sh "make clean"
    sh "make"
    sh "cp *.#{dlext} ../../lib/"
  end
end

desc 'cleanup the extensions'
task :cleanup do
  sh "rm -rf lib/debug_inspector.#{dlext}"
  chdir "#{direc}/ext/debug_inspector/" do
    sh 'make clean' rescue nil
  end
end

desc "(re)install gem"
task :reinstall => :gem do
  sh "gem uninstall debug_inspector" rescue nil
  sh "gem install -l #{direc}/debug_inspector-#{DebugInspector::VERSION}.gem"
end

task :install => :reinstall

desc "build all platform gems at once"
task :gem => [:clean, :rmgems] do
  sh "gem build #{direc}/debug_inspector.gemspec"
end

desc "remove all platform gems"
task :rmgems do
  sh "rm #{direc}/*.gem" rescue nil
end

desc "build and push latest gems"
task :pushgems => :gem do
  chdir(direc) do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end
