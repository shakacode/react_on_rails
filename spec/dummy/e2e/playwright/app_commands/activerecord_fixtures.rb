# frozen_string_literal: true

# you can delete this file if you don't use Rails Test Fixtures

raise "ActiveRecord is not defined. Unable to load fixtures." unless defined?(ActiveRecord)

require "active_record/fixtures"

fixtures_dir = command_options.try(:[], "fixtures_dir")
fixture_files = command_options.try(:[], "fixtures")

fixtures_dir ||= ActiveRecord::Tasks::DatabaseTasks.fixtures_path
fixture_files ||= Dir["#{fixtures_dir}/**/*.yml"].map { |f| f[(fixtures_dir.size + 1)..-5] }

Rails.logger.debug "loading fixtures: { dir: #{fixtures_dir}, files: #{fixture_files} }"
ActiveRecord::FixtureSet.reset_cache
ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, fixture_files)
"Fixtures Done" # this gets returned
