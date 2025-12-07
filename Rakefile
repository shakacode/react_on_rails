# frozen_string_literal: true

# Root Rakefile for monorepo development
#
# This file enables running rake tasks from the monorepo root directory.
# It loads:
#   1. Monorepo-level tasks from ./rakelib/ (e.g., release task for both gems)
#   2. The react_on_rails gem's Rakefile
#   3. The react_on_rails gem's rakelib tasks
#
# Usage: bundle exec rake -T (from monorepo root)
#
# Note: This is for development only. When the gem is installed in a Rails app,
# Rails::Engine handles rake task loading automatically from lib/tasks/.

# Define gem_root helper for use by rake tasks
def gem_root
  File.expand_path("react_on_rails", __dir__)
end

# Load the open-source gem's Rakefile
load File.expand_path("Rakefile", gem_root)

# Load all rake tasks from the gem's rakelib directory
# Rake only auto-loads from ./rakelib in the current working directory,
# so we must explicitly load from the subdirectory.
Dir[File.join(gem_root, "rakelib", "*.rake")].each { |rake_file| load rake_file }

# NOTE: Monorepo-level rake tasks from ./rakelib/ are auto-loaded by Rake.
# Do NOT explicitly load them here, as that would cause tasks to be defined twice
# and their bodies would run twice (Rake appends duplicate task definitions).
