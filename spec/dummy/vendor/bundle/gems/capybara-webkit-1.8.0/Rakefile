require 'bundler'
require 'rspec/core/rake_task'
require_relative './lib/capybara_webkit_builder'
require 'appraisal'

namespace :bundler do
  Bundler::GemHelper.install_tasks
end

desc "Generate a Makefile using qmake"
file 'Makefile' do
  CapybaraWebkitBuilder.makefile('CONFIG+=test') or exit(1)
end

desc "Regenerate dependencies using qmake"
task :qmake => 'Makefile' do
  CapybaraWebkitBuilder.qmake or exit(1)
end

desc "Build the webkit server"
task :build => :qmake do
  CapybaraWebkitBuilder.build or exit(1)
end

desc "Run QtTest unit tests for webkit server"
task :check => :build do
  sh("make check") or exit(1)
end

file 'bin/webkit_server' => :build

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = "--format progress"
end

task :spec => :build

desc "Default: build and run all specs"
task :default => [:check, :spec]

desc "Generate a new command called NAME"
task :generate_command do
  name = ENV['NAME'] or raise "Provide a name with NAME="

  %w(h cpp).each do |extension|
    File.open("templates/Command.#{extension}", "r") do |source_file|
      contents = source_file.read
      contents.gsub!("NAME", name)
      File.open("src/#{name}.#{extension}", "w") do |target_file|
        target_file.write(contents)
      end
    end
  end

  Dir.glob("src/*.pro").each do |project_file_name|
    project = IO.read(project_file_name)
    project.gsub!(/^(HEADERS = .*)/, "\\1\n  #{name}.h \\")
    project.gsub!(/^(SOURCES = .*)/, "\\1\n  #{name}.cpp \\")
    File.open(project_file_name, "w") { |file| file.write(project) }
  end

  File.open("src/find_command.h", "a") do |file|
    file.write("CHECK_COMMAND(#{name})\n")
  end

  command_factory_file_name = "src/CommandFactory.cpp"
  command_factory = IO.read(command_factory_file_name)
  command_factory.sub!(/^$/, "#include \"#{name}.h\"\n")
  File.open(command_factory_file_name, "w") { |file| file.write(command_factory) }
end
