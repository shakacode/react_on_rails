# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :rbs do
  desc "Validate RBS type signatures"
  task :validate do
    require "rbs"
    require "rbs/cli"

    puts "Validating RBS type signatures..."

    # Run RBS validate
    result = system("bundle exec rbs -I sig validate")

    case result
    when true
      puts "✓ RBS validation passed"
    when false
      puts "✗ RBS validation failed"
      exit 1
    when nil
      puts "✗ RBS command not found or could not be executed"
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
