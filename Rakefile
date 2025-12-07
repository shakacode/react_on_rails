# frozen_string_literal: true

# Root Rakefile for monorepo development
#
# This file enables running rake tasks from the monorepo root directory.
# It delegates to the react_on_rails gem's Rakefile and loads all rake tasks
# from the gem's rakelib directory.
#
# Usage: bundle exec rake -T (from monorepo root)
#
# Note: This is for development only. When the gem is installed in a Rails app,
# Rails::Engine handles rake task loading automatically from lib/tasks/.

gem_root = File.expand_path("react_on_rails", __dir__)

# Load the open-source gem's Rakefile
load File.expand_path("Rakefile", gem_root)

# Load all rake tasks from the gem's rakelib directory
# Rake only auto-loads from ./rakelib in the current working directory,
# so we must explicitly load from the subdirectory.
Dir[File.join(gem_root, "rakelib", "*.rake")].each { |rake_file| load rake_file }
