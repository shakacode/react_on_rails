dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)

PROJECT_NAME = "pry-doc"

require 'latest_ruby'
require 'rake/clean'
require "#{direc}/lib/#{PROJECT_NAME}/version"

desc "run tests"
task :test do
  sh "bacon -k #{direc}/spec/pry-doc_spec.rb"
end
task :spec => :test

task :default => :test

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall pry-doc" rescue nil
  sh "gem install #{direc}/pkg/pry-doc-#{PryDoc::VERSION}.gem"
end

desc "build all platform gems at once"
task :gems => :rmgems do
  mkdir_p "pkg"
  sh 'gem build *.gemspec'
  mv "pry-doc-#{PryDoc::VERSION}.gem", "pkg"
end

desc "remove all platform gems"
task :rmgems do
  rm_rf 'pkg'
end

desc "Build gemspec"
task :gemspec => "ruby:gemspec"

desc "Show version"
task :version do
  puts "PryDoc version: #{PryDoc::VERSION}"
end

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{direc}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end

def download_ruby(ruby)
  system "mkdir rubies"
  system "wget #{ ruby.link } --directory-prefix=rubies --no-clobber"
  File.join('rubies', ruby.filename)
end

def unpackage_ruby(path)
  system "mkdir rubies/ruby"
  system "tar xzvf #{ path } --directory=rubies/ruby"
end

def cd_into_ruby
  Dir.chdir(Dir['rubies/ruby/*'].first)
end

def generate_yard
  system %{
    bash -c "paste <(find . -maxdepth 1 -name '*.c') <(find ext -name '*.c') |
      xargs yardoc --no-output"
  }
end

def replace_existing_docs(ver)
  system %|mkdir -p ../../../lib/pry-doc/core_docs_#{ ver } && cp -r .yardoc/* "$_"|
  Dir.chdir(File.expand_path(File.dirname(__FILE__)))
end

def clean_up
  system "rm -rf rubies"
end

def generate_docs_for(ruby_ver, latest_ruby)
  path = download_ruby(latest_ruby)
  unpackage_ruby(path)
  cd_into_ruby
  generate_yard
  replace_existing_docs(ruby_ver)
  clean_up
end

desc "Generate the latest Ruby 1.9 docs"
task "gen19" do
  generate_docs_for('19', Latest.ruby19)
end

desc "Generate the latest Ruby 2.0 docs"
task "gen20" do
  generate_docs_for('20', Latest.ruby20)
end

desc "Generate the latest Ruby 2.1 docs"
task "gen21" do
  generate_docs_for('21', Latest.ruby21)
end

desc "Generate the latest Ruby 2.2 docs"
task "gen22" do
  generate_docs_for('22', Latest.ruby22)
end
