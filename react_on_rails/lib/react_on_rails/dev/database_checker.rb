# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"

module ReactOnRails
  module Dev
    # DatabaseChecker validates that the Rails database is properly set up
    # before starting the development server.
    #
    # This prevents confusing errors when running bin/dev on a fresh checkout
    # or after database cleanup.
    #
    # Checks performed:
    # 1. Database exists and is accessible
    # 2. Migrations are up to date (optional warning)
    #
    # Can be disabled via:
    # - Environment variable: SKIP_DATABASE_CHECK=true
    # - CLI flag: bin/dev --skip-database-check
    # - Configuration: ReactOnRails.configure { |c| c.check_database_on_dev_start = false }
    #
    # Note: This check spawns a Rails runner process which adds ~1-2 seconds to startup.
    # Disable it if this overhead is unacceptable for your workflow.
    #
    class DatabaseChecker
      class << self
        # Check if the database is set up and accessible
        #
        # @param skip [Boolean] if true, skip the check entirely
        # @return [Boolean] true if database is ready (or check was skipped), false otherwise
        def check_database(skip: false)
          return true if should_skip_check?(skip)

          print_checking_message
          result = run_database_check

          case result[:status]
          when :ok
            print_database_ok
            check_pending_migrations
            true
          when :error
            print_database_error(result[:error])
            false
          else
            true # Unknown status - let server start and show the real error
          end
        end

        private

        def should_skip_check?(skip_flag)
          # 1. CLI flag takes highest priority
          return true if skip_flag

          # 2. Environment variable
          return true if ENV["SKIP_DATABASE_CHECK"] == "true"

          # 3. ReactOnRails configuration (if available)
          if defined?(ReactOnRails) && ReactOnRails.respond_to?(:configuration)
            config = ReactOnRails.configuration
            return true if config.respond_to?(:check_database_on_dev_start) &&
                           config.check_database_on_dev_start == false
          end

          false
        end

        def run_database_check
          check_script = <<~RUBY
            begin
              ActiveRecord::Base.connection.execute('SELECT 1')
              puts 'DATABASE_OK'
            rescue => e
              puts 'DATABASE_ERROR'
              puts e.message
            end
          RUBY

          # SECURITY: Using array form of Open3.capture3 is safe from command injection.
          # The check_script is hardcoded above and never includes user input.
          stdout, stderr, status = Open3.capture3("bin/rails", "runner", check_script)
          parse_check_result(stdout, stderr, status)
        rescue Errno::ENOENT
          { status: :not_rails_app, error: "bin/rails not found" }
        rescue StandardError => e
          { status: :unknown_error, error: e.message }
        end

        def parse_check_result(stdout, stderr, status)
          return { status: :error, error: "#{stdout}\n#{stderr}".strip } unless status.success?

          lines = stdout.strip.split("\n")
          case lines.first
          when "DATABASE_OK" then { status: :ok }
          when "DATABASE_ERROR" then { status: :error, error: lines[1..].join("\n") }
          else
            if stdout.include?("DATABASE_OK")
              { status: :ok }
            else
              { status: :error, error: "#{stdout}\n#{stderr}".strip }
            end
          end
        end

        def check_pending_migrations
          stdout, _stderr, status = Open3.capture3("bin/rails", "db:migrate:status")
          return unless status.success? && stdout.include?(" down ")

          print_pending_migrations_warning
        rescue StandardError => e
          # Ignore errors - this is just a helpful warning.
          # Common case: schema_migrations table doesn't exist yet on brand new databases.
          warn "[ReactOnRails] Migration check failed: #{e.message}" if ENV["DEBUG"]
          nil
        end

        def print_checking_message
          puts "\n#{Rainbow('Checking database setup...').cyan}"
        end

        def print_database_ok
          puts Rainbow("   Database is accessible").green
        end

        def print_pending_migrations_warning
          puts Rainbow("   Pending migrations detected").yellow
          puts Rainbow("     Run: bin/rails db:migrate").yellow
        end

        def print_database_error(error)
          puts Rainbow("   Database check failed").red
          puts ""
          puts "#{Rainbow("   Error: #{truncate_error(error)}").red}\n" if error && !error.empty?
          puts Rainbow("To fix, run:").yellow
          puts ""
          puts "   #{Rainbow('bin/rails db:prepare').green}  # Creates database if needed and runs pending migrations"
          puts ""
          puts Rainbow("Then run bin/dev again.").blue
          puts ""
        end

        def truncate_error(error)
          return error if error.length <= 500

          "#{error[0, 500]}...\n           (Set DEBUG=1 for full error)"
        end
      end
    end
  end
end
