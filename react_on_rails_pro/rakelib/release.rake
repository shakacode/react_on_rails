# frozen_string_literal: true

require_relative "task_helpers"
require "react_on_rails"

desc("⚠️  DEPRECATED: Use the root release task instead.

This task has been deprecated in favor of the unified release script located at the
repository root. The unified script manages versions and releases for all React on Rails
packages and gems together using synchronized versioning.

To release all packages, run from the repository root:
  cd .. && rake release[VERSION]

Examples:
  cd .. && rake release[patch]                  # Bump patch version
  cd .. && rake release[minor]                  # Bump minor version
  cd .. && rake release[16.2.0]                 # Set explicit version
  cd .. && rake release[patch,true]             # Dry run

For more information, run: cd .. && rake -D release")

task :release, %i[version dry_run] do |_t, args|
  puts "\n#{'=' * 80}"
  puts "⚠️  DEPRECATED TASK"
  puts "=" * 80
  puts "\nThis release task is deprecated. Please use the unified release task from the root."
  puts "\nRun this command instead:"
  puts "  cd .. && rake release[#{args[:version] || 'patch'}#{args[:dry_run] ? ",#{args[:dry_run]}" : ''}]"
  puts "\n#{'=' * 80}"
  puts "\nWould you like to run the root release task now? (y/n)"

  response = $stdin.gets.chomp.downcase
  if %w[y yes].include?(response)
    # Change to root directory and run release task
    root_dir = File.expand_path("..", __dir__)
    Dir.chdir(root_dir) do
      version_arg = args[:version] || "patch"
      dry_run_arg = args[:dry_run] || ""

      # Build the command
      cmd_parts = ["rake", "release[#{version_arg}"]
      cmd_parts << ",#{dry_run_arg}" unless dry_run_arg.empty?
      cmd_parts << "]"

      exec(cmd_parts.join)
    end
  else
    puts "\nRelease cancelled. Please run the unified release task manually from the root directory."
    exit 1
  end
end
