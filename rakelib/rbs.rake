# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :rbs do
  desc "Validate RBS type signatures"
  task :validate do
    require "rbs"
    require "rbs/cli"

    puts "Validating RBS type signatures..."

    # IMPORTANT: Always use 'bundle exec' even though rake runs in bundle context
    # Reason: Direct 'rake' calls (without 'bundle exec rake') won't have gems in path
    # This ensures the task works regardless of how the user invokes rake
    # Redirect stderr to suppress bundler warnings that don't affect validation
    result = system("bundle exec rbs -I sig validate 2>/dev/null")

    case result
    when true
      puts "✓ RBS validation passed"
    when false
      # Re-run with stderr to show actual validation errors
      puts "Validation errors detected:"
      system("bundle exec rbs -I sig validate")
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

  desc "Run Steep type checker"
  task :steep do
    puts "Running Steep type checker..."

    # IMPORTANT: Always use 'bundle exec' even though rake runs in bundle context
    # Reason: Direct 'rake' calls (without 'bundle exec rake') won't have gems in path
    # This ensures the task works regardless of how the user invokes rake
    # Redirect stderr to suppress bundler warnings
    result = system("bundle exec steep check 2>/dev/null")

    case result
    when true
      puts "✓ Steep type checking passed"
    when false
      # Re-run with stderr to show actual type errors
      puts "Type checking errors detected:"
      system("bundle exec steep check")
      exit 1
    when nil
      puts "✗ Steep command not found or could not be executed"
      exit 1
    end
  end

  desc "Run all RBS checks (validate + steep)"
  task all: %i[validate steep]
end
# rubocop:enable Metrics/BlockLength
