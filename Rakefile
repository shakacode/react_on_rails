# frozen_string_literal: true

# Root Rakefile for developer convenience
# Delegates to the react_on_rails gem's Rakefile for development

gem_root = File.expand_path("react_on_rails", __dir__)

# Load the open-source gem's Rakefile
load File.expand_path("Rakefile", gem_root)

# Load all rake tasks from the gem's rakelib directory
# Rake auto-loads from ./rakelib but not from subdirectories
Dir[File.join(gem_root, "rakelib", "*.rake")].each { |rake_file| load rake_file }
