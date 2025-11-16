# frozen_string_literal: true

require "open3"
require "timeout"

# NOTE: Pro package does not include Steep tasks (:steep, :all) as it does not
# use Steep type checker. Only RBS validation is performed.
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
      Open3.capture3("bundle exec rbs -I sig validate")
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
end
# rubocop:enable Metrics/BlockLength
