# encoding: UTF-8
# -*- ruby -*-

require 'rubygems'

require 'erb'
require 'rake/testtask'
require 'rubygems/package_task'
require 'rake/clean'
require 'yard'

# Load the gemspec file for this project.
GEMSPEC = Dir['*.gemspec'].first
SPEC = eval(File.read(GEMSPEC), nil, GEMSPEC)

# The path to the version.rb file and a string to eval to find the version.
VERSION_RB = "lib/#{SPEC.name.gsub('-', '/')}/version.rb"
VERSION_REF =
  SPEC.name.split('-').map do |subname|
    subname.split('_').map(&:capitalize).join
  end.join('::') + "::VERSION"

# A dynamically generated list of files that should match the manifest (the
# combined contents of SPEC.files and SPEC.test_files).  The idea is for this
# list to contain all project files except for those that have been explicitly
# excluded.  This list will be compared with the manifest from the SPEC in order
# to help catch the addition or removal of files to or from the project that
# have not been accounted for either by an exclusion here or an inclusion in the
# SPEC manifest.
#
# NOTE:
# It is critical that the manifest is *not* automatically generated via globbing
# and the like; otherwise, this will yield a simple comparison between
# redundantly generated lists of files that probably will not protect the
# project from the unintentional inclusion or exclusion of files in the
# distribution.
PKG_FILES = FileList.new(Dir.glob('**/*', File::FNM_DOTMATCH)) do |files|
  # Exclude anything that doesn't exist as well as directories.
  files.exclude {|file| ! File.exist?(file) || File.directory?(file)}
  # Exclude Git administrative files.
  files.exclude(%r{(^|[/\\])\.git(ignore|modules|keep)?([/\\]|$)})
  # Exclude editor swap/temporary files.
  files.exclude('**/.*.sw?')
  # Exclude gemspec files.
  files.exclude('*.gemspec')
  # Exclude the README template file.
  files.exclude('README.md.erb')
  # Exclude resources for bundler.
  files.exclude('Gemfile', 'Gemfile.lock')
  files.exclude(%r{^.bundle([/\\]|$)})
  files.exclude(%r{^vendor/bundle([/\\]|$)})
  # Exclude generated content, except for the README file.
  files.exclude(%r{^(pkg|doc|.yardoc)([/\\]|$)})
  # Exclude Rubinius compiled Ruby files.
  files.exclude('**/*.rbc')
  files.exclude('.rbx/**/*')
end

# Make sure that :clean and :clobber will not whack the repository files.
CLEAN.exclude('.git/**')
# Vim swap files are fair game for clean up.
CLEAN.include('**/.*.sw?')

# Returns the value of the VERSION environment variable as a Gem::Version object
# assuming it is set and a valid Gem version string.  Otherwise, raises an
# exception.
def get_version_argument
  version = ENV['VERSION']
  if version.to_s.empty?
    raise "No version specified: Add VERSION=X.Y.Z to the command line"
  end
  begin
    Gem::Version.create(version.dup)
  rescue ArgumentError
    raise "Invalid version specified in `VERSION=#{version}'"
  end
end

# Performs an in place, per line edit of the file indicated by _path_ by calling
# the sub method on each line and passing _pattern_, _replacement_, and _b_ as
# arguments.
def file_sub(path, pattern, replacement = nil, &b)
  tmp_path = "#{path}.tmp"
  File.open(path) do |infile|
    File.open(tmp_path, 'w') do |outfile|
      infile.each do |line|
        outfile.write(line.sub(pattern, replacement, &b))
      end
    end
  end
  File.rename(tmp_path, path)
end

# Updates the version string in the gemspec file and a version.rb file it to the
# string in _version_.
def set_version(version)
  file_sub(GEMSPEC, /(\.version\s*=\s*).*/, "\\1'#{version}'")
  file_sub(VERSION_RB, /^(\s*VERSION\s*=\s*).*/, "\\1'#{version}'")
end

# Returns a string that is line wrapped at word boundaries, where each line is
# no longer than _line_width_ characters.
#
# This is mostly lifted directly from ActionView::Helpers::TextHelper.
def word_wrap(text, line_width = 80)
  text.split("\n").collect do |line|
    line.length > line_width ?
      line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip :
      line
  end * "\n"
end

desc 'Alias for build:gem'
task :build => 'build:gem'

# Build related tasks.
namespace :build do
  # Ensure that the manifest is consulted when building the gem.  Any
  # generated/compiled files should be available at that time.
  task :gem => :check_manifest

  # Create the gem and package tasks.
  Gem::PackageTask.new(SPEC).define

  desc 'Verify the manifest'
  task :check_manifest do
    manifest_files = (SPEC.files + SPEC.test_files).sort.uniq
    pkg_files = PKG_FILES.sort.uniq
    if manifest_files != pkg_files then
      common_files = manifest_files & pkg_files
      manifest_files -= common_files
      pkg_files -= common_files
      message = ["The manifest does not match the automatic file list."]
      unless manifest_files.empty? then
        message << "  Extraneous files:\n    " + manifest_files.join("\n    ")
      end
      unless pkg_files.empty?
        message << "  Missing files:\n    " + pkg_files.join("\n    ")
      end
      raise message.join("\n")
    end
  end

  # Creates the README.md file from a template, the license file and the gemspec
  # contents.
  file 'README.md' => ['README.md.erb', 'LICENSE', GEMSPEC] do
    spec = SPEC
    File.open('README.md', 'w') do |readme|
      readme.write(
        ERB.new(File.read('README.md.erb'), nil, '-').result(binding)
      )
    end
  end
end

# Ensure that the clobber task also clobbers package files.
task :clobber => 'build:clobber_package'

# Create the documentation task.
YARD::Rake::YardocTask.new
# Ensure that the README file is (re)generated first.
task :yard => 'README.md'

# Gem related tasks.
namespace :gem do
  desc 'Alias for build:gem'
  task :build => 'build:gem'

  desc 'Publish the gemfile'
  task :publish => ['version:check', :test, 'repo:tag', :build] do
    sh "gem push pkg/#{SPEC.name}-#{SPEC.version}*.gem"
  end
end

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

# Version string management tasks.
namespace :version do
  desc 'Set the version for the project to a specified version'
  task :set do
    set_version(get_version_argument)
  end

  desc 'Set the version for the project back to 0.0.0'
  task :reset do
    set_version('0.0.0')
  end

  desc 'Check that all version strings are correctly set'
  task :check => ['version:check:spec', 'version:check:version_rb', 'version:check:news']

  namespace :check do
    desc 'Check that the version in the gemspec is correctly set'
    task :spec do
      version = get_version_argument
      if version != SPEC.version
        raise "The given version `#{version}' does not match the gemspec version `#{SPEC.version}'"
      end
    end

    desc 'Check that the version in the version.rb file is correctly set'
    task :version_rb do
      version = get_version_argument
      begin
        load VERSION_RB
        internal_version = Gem::Version.create(eval(VERSION_REF))
        if version != internal_version
          raise "The given version `#{version}' does not match the version.rb version `#{internal_version}'"
        end
      rescue ArgumentError
        raise "Invalid version specified in `#{VERSION_RB}'"
      end
    end

    desc 'Check that the NEWS.md file mentions the version'
    task :news do
      version = get_version_argument
      begin
        File.open('NEWS.md') do |news|
          unless news.each_line.any? {|l| l =~ /^## v#{Regexp.escape(version.to_s)} /}
            raise "The NEWS.md file does not mention version `#{version}'"
          end
        end
      rescue Errno::ENOENT
        raise 'No NEWS.md file found'
      end
    end
  end
end

# Repository and workspace management tasks.
namespace :repo do
  desc 'Tag the current HEAD with the version string'
  task :tag => :check_workspace do
    version = get_version_argument
    sh "git tag -s -m 'Release v#{version}' v#{version}"
  end

  desc 'Ensure the workspace is fully committed and clean'
  task :check_workspace => ['README.md'] do
    unless `git status --untracked-files=all --porcelain`.empty?
      raise 'Workspace has been modified.  Commit pending changes and try again.'
    end
  end
end
