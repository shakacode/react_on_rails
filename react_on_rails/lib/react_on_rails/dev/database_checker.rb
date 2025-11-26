# frozen_string_literal: true

require "rainbow"

module ReactOnRails
  module Dev
    # DatabaseChecker validates that the database is set up before starting
    # the development server.
    #
    # This prevents confusing errors buried in combined Foreman/Overmind logs
    # and provides clear guidance on how to set up the database.
    #
    class DatabaseChecker
      class << self
        # Check if the database is set up and provide helpful output
        #
        # @return [Boolean] true if database is ready, false otherwise
        def check_database
          return true unless rails_available?

          check_and_report_database
        end

        private

        def rails_available?
          defined?(Rails) && defined?(ActiveRecord::Base)
        end

        def check_and_report_database
          print_check_header

          if database_ready?
            print_database_ok
            true
          else
            print_database_failed
            false
          end
        end

        def database_ready?
          # Try to establish connection and run a simple query
          ActiveRecord::Base.connection.execute("SELECT 1")
          true
        rescue ActiveRecord::NoDatabaseError
          # Database doesn't exist
          @error_type = :no_database
          false
        rescue ActiveRecord::PendingMigrationError
          # Database exists but migrations are pending
          @error_type = :pending_migrations
          false
        rescue ActiveRecord::ConnectionNotEstablished,
               ActiveRecord::StatementInvalid => e
          # Connection failed or other database error
          @error_type = :connection_error
          @error_message = e.message
          false
        rescue StandardError => e
          # Unexpected error - log but don't block startup
          # This allows apps without databases to still use bin/dev
          warn "Database check warning: #{e.message}" if ENV["DEBUG"]
          true
        end

        def print_check_header
          puts ""
          puts Rainbow("🗄️  Checking database...").cyan.bold
          puts ""
        end

        def print_database_ok
          puts "   #{Rainbow('✓').green} Database is ready"
          puts ""
        end

        # rubocop:disable Metrics/AbcSize
        def print_database_failed
          puts "   #{Rainbow('✗').red} Database is not ready"
          puts ""
          puts Rainbow("❌ Database not set up!").red.bold
          puts ""

          case @error_type
          when :no_database
            puts Rainbow("The database does not exist.").yellow
            puts ""
            puts Rainbow("Run one of these commands:").cyan.bold
            puts "   #{Rainbow('bin/rails db:setup').green}     # Create database, load schema, seed data"
            puts "   #{Rainbow('bin/rails db:create').green}    # Just create the database"
          when :pending_migrations
            puts Rainbow("The database exists but has pending migrations.").yellow
            puts ""
            puts Rainbow("Run this command:").cyan.bold
            puts "   #{Rainbow('bin/rails db:migrate').green}   # Run pending migrations"
          when :connection_error
            puts Rainbow("Could not connect to the database.").yellow
            if @error_message
              puts ""
              puts Rainbow("Error: #{@error_message}").red
            end
            puts ""
            puts Rainbow("Possible solutions:").cyan.bold
            puts "   #{Rainbow('1.').yellow} Check if your database server is running"
            puts "   #{Rainbow('2.').yellow} Verify database.yml configuration"
            puts "   #{Rainbow('3.').yellow} Run #{Rainbow('bin/rails db:setup').green} to create the database"
          end

          puts ""
          puts Rainbow("💡 Tip:").blue.bold
          puts "   After fixing the database, run #{Rainbow('bin/dev').green} again"
          puts ""
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
