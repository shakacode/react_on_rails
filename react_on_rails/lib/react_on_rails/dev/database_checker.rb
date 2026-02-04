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
    class DatabaseChecker
      class << self
        # Check if the database is set up and accessible
        #
        # @return [Boolean] true if database is ready, false otherwise
        def check_database
          print_checking_message
          result = run_database_check

          case result[:status]
          when :ok
            print_database_ok
            check_pending_migrations
            true
          when :no_database
            print_no_database(result[:error])
            false
          when :connection_error
            print_connection_error(result[:error])
            false
          when :rails_error
            print_rails_error(result[:error])
            false
          else
            true # Unknown error - let server start and show the real error
          end
        end

        private

        def run_database_check
          check_script = <<~RUBY
            begin
              ActiveRecord::Base.connection.execute('SELECT 1')
              puts 'DATABASE_OK'
            rescue ActiveRecord::NoDatabaseError => e
              puts 'NO_DATABASE'
              puts e.message
            rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad, Mysql2::Error => e
              puts 'CONNECTION_ERROR'
              puts e.message
            rescue => e
              puts 'RAILS_ERROR'
              puts e.class.name
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
          return { status: :rails_error, error: "#{stdout}\n#{stderr}".strip } unless status.success?

          lines = stdout.strip.split("\n")
          case lines.first
          when "DATABASE_OK" then { status: :ok }
          when "NO_DATABASE" then { status: :no_database, error: lines[1..].join("\n") }
          when "CONNECTION_ERROR" then { status: :connection_error, error: lines[1..].join("\n") }
          when "RAILS_ERROR" then { status: :rails_error, error: lines[1..].join("\n") }
          else
            if stdout.include?("DATABASE_OK")
              { status: :ok }
            else
              { status: :rails_error,
                error: "#{stdout}\n#{stderr}".strip }
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
          puts "\n#{Rainbow('🔍 Checking database setup...').cyan}"
        end

        def print_database_ok
          puts Rainbow("   ✓ Database is accessible").green
        end

        def print_pending_migrations_warning
          puts Rainbow("   ⚠ Pending migrations detected").yellow
          puts Rainbow("     Consider running: bin/rails db:migrate").yellow
        end

        def print_no_database(error)
          puts Rainbow("   ✗ Database does not exist").red
          puts "\n#{Rainbow('❌ Database not set up!').red.bold}\n\n"
          puts "#{Rainbow("   Error: #{truncate_error(error)}").red}\n" if error && !error.empty?
          puts Rainbow("Run one of these commands first:").yellow
          puts "\n   #{Rainbow('bin/rails db:setup').green}     # For new setup (creates, migrates, seeds)"
          puts "   #{Rainbow('bin/rails db:create').green}    # Just create the database"
          puts "\n#{Rainbow('💡 Then run bin/dev again').blue}\n"
        end

        # rubocop:disable Metrics/AbcSize
        def print_connection_error(error)
          puts Rainbow("   ✗ Cannot connect to database").red
          puts "\n#{Rainbow('❌ Database connection failed!').red.bold}\n\n"
          puts "#{Rainbow("   Error: #{truncate_error(error)}").red}\n" if error && !error.empty?
          puts Rainbow("Common causes:").yellow
          puts "\n   • Database server not running (PostgreSQL, MySQL, etc.)"
          puts "   • Incorrect database credentials in config/database.yml"
          puts "   • Database host/port misconfigured"
          puts "\n#{Rainbow('For PostgreSQL:').cyan}"
          puts "   #{Rainbow('brew services start postgresql').green}  # macOS with Homebrew"
          puts "   #{Rainbow('sudo systemctl start postgresql').green} # Linux with systemd"
          puts "\n#{Rainbow('For MySQL:').cyan}"
          puts "   #{Rainbow('brew services start mysql').green}       # macOS with Homebrew"
          puts "   #{Rainbow('sudo systemctl start mysql').green}      # Linux with systemd"
          puts "\n#{Rainbow('💡 Start your database server, then run bin/dev again').blue}\n"
        end
        # rubocop:enable Metrics/AbcSize

        def print_rails_error(error)
          puts Rainbow("   ✗ Rails error during database check").red
          puts "\n#{Rainbow('❌ Could not verify database!').red.bold}\n\n"
          puts "#{Rainbow("   Error: #{truncate_error(error)}").red}\n" if error && !error.empty?
          puts Rainbow("This might be caused by:").yellow
          puts "\n   • Missing environment variables"
          puts "   • Configuration errors in database.yml"
          puts "   • Missing gems (run: bundle install)"
          puts "\n#{Rainbow('💡 Fix the error above, then run bin/dev again').blue}\n"
        end

        def truncate_error(error)
          return error if error.length <= 500

          "#{error[0, 500]}...\n           (Set DEBUG=1 for full error)"
        end
      end
    end
  end
end
