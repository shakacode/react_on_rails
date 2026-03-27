# frozen_string_literal: true

require "open3"
require "timeout"

# rubocop:disable Metrics/BlockLength
namespace :rbs do
  desc "Validate RBS type signatures"
  task :validate do
    require "rbs"
    require "rbs/cli"

    puts "Validating RBS type signatures..."

    # Use Open3 for better error handling - captures stdout, stderr, and exit status separately
    # This allows us to distinguish between actual validation errors and warnings
    # Note: Must use bundle exec even though rake runs in bundle context because
    # spawned shell commands via Open3.capture3() do NOT inherit bundle context
    # Wrap in Timeout to prevent hung processes in CI environments (60 second timeout)
    stdout, stderr, status = Timeout.timeout(60) do
      Open3.capture3("bundle exec rbs -I sig -r pathname validate")
    end

    if status.success?
      puts "✓ RBS validation passed"
    else
      puts "✗ RBS validation failed"
      puts stdout unless stdout.empty?
      warn stderr unless stderr.empty?
      exit 1
    end
  end

  desc "Check RBS type signatures (alias for validate)"
  task check: :validate

  desc "List all RBS files"
  task :list do
    sig_files = Dir.glob("sig/**/*.rbs")
    puts "RBS type signature files:"
    sig_files.each { |f| puts "  #{f}" }
    puts "\nTotal: #{sig_files.count} files"
  end

  desc "Run Steep type checker"
  task :steep do
    puts "Running Steep type checker..."

    # Use Open3 for better error handling
    # Note: Must use bundle exec even though rake runs in bundle context because
    # spawned shell commands via Open3.capture3() do NOT inherit bundle context
    # Wrap in Timeout to prevent hung processes in CI environments (60 second timeout)
    stdout, stderr, status = Timeout.timeout(60) do
      Open3.capture3("bundle exec steep check")
    end

    if status.success?
      puts "✓ Steep type checking passed"
    else
      puts "✗ Steep type checking failed"
      puts stdout unless stdout.empty?
      warn stderr unless stderr.empty?
      exit 1
    end
  end

  desc "Run all RBS checks (validate + steep)"
  task all: %i[validate steep]
end
# rubocop:enable Metrics/BlockLength
