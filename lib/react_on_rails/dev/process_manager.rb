# frozen_string_literal: true

require "timeout"

module ReactOnRails
  module Dev
    class ProcessManager
      # Timeout for version check operations to prevent hanging
      VERSION_CHECK_TIMEOUT = 5

      class << self
        # Check if a process is available and usable in the current execution context
        # This accounts for bundler context where system commands might be intercepted
        def installed?(process)
          installed_in_current_context?(process)
        end

        def ensure_procfile(procfile)
          return if File.exist?(procfile)

          warn <<~MSG
            ERROR:
            Please ensure `#{procfile}` exists in your project!
          MSG
          exit 1
        end

        def run_with_process_manager(procfile)
          # Validate procfile path for security
          unless valid_procfile_path?(procfile)
            warn "ERROR: Invalid procfile path: #{procfile}"
            exit 1
          end

          # Clean up stale files before starting
          FileManager.cleanup_stale_files

          # Try process managers in order of preference
          return if run_process_if_available("overmind", ["start", "-f", procfile])
          return if run_process_if_available("foreman", ["start", "-f", procfile])

          show_process_manager_installation_help
          exit 1
        end

        private

        # Check if a process is actually usable in the current execution context
        # This is important for commands that might be intercepted by bundler
        def installed_in_current_context?(process)
          # Try to execute the process with version flags to see if it works
          # Use system() because that's how we'll actually call it later
          version_flags_for(process).any? do |flag|
            # Add timeout to prevent hanging on version checks
            Timeout.timeout(VERSION_CHECK_TIMEOUT) do
              system(process, flag, out: File::NULL, err: File::NULL)
            end
          end
        rescue Errno::ENOENT, Timeout::Error
          false
        end

        # Get appropriate version flags for different processes
        def version_flags_for(process)
          case process
          when "overmind"
            ["--version"]
          when "foreman"
            ["--version", "-v"]
          else
            ["--version", "-v", "-V"]
          end
        end

        # Try to run a process if it's available, with intelligent fallback strategy
        # Returns true if process was found and executed, false if not available
        def run_process_if_available(process, args)
          # First attempt: try in current context (works for bundled processes)
          return system(process, *args) if installed?(process)

          # Second attempt: try in system context (works for system-installed processes)
          return run_process_outside_bundle(process, args) if process_available_in_system?(process)

          # Process not available in either context
          false
        end

        # Run a process outside of bundler context
        # This allows using system-installed processes even when they're not in the Gemfile
        def run_process_outside_bundle(process, args)
          if defined?(Bundler)
            with_unbundled_context do
              system(process, *args)
            end
          else
            # Fallback if Bundler is not available
            system(process, *args)
          end
        end

        # Check if a process is available system-wide (outside bundle context)
        def process_available_in_system?(process)
          return false unless defined?(Bundler)

          with_unbundled_context do
            # Try version flags to check if process exists outside bundler context
            version_flags_for(process).any? do |flag|
              # Add timeout to prevent hanging on version checks
              Timeout.timeout(VERSION_CHECK_TIMEOUT) do
                system(process, flag, out: File::NULL, err: File::NULL)
              end
            end
          end
        rescue Errno::ENOENT, Timeout::Error
          false
        end

        # DRY helper method for Bundler context switching with API compatibility
        # Supports both new (with_unbundled_env) and legacy (with_clean_env) Bundler APIs
        def with_unbundled_context(&block)
          if Bundler.respond_to?(:with_unbundled_env)
            Bundler.with_unbundled_env(&block)
          elsif Bundler.respond_to?(:with_clean_env)
            Bundler.with_clean_env(&block)
          else
            # Fallback if neither method is available (very old Bundler versions)
            yield
          end
        end

        # Improved error message with helpful guidance
        def show_process_manager_installation_help
          warn <<~MSG
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ERROR: Process Manager Not Found
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            To run the React on Rails development server, you need either 'overmind' or
            'foreman' installed on your system.

            RECOMMENDED INSTALLATION:

              macOS:    brew install overmind
              Linux:    gem install foreman

            IMPORTANT:
            DO NOT add foreman to your Gemfile. Install it globally on your system.

            For more information about why foreman should not be in your Gemfile, see:
            https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman

            After installation, try running this script again.
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          MSG
        end

        def valid_procfile_path?(procfile)
          # Reject paths with shell metacharacters
          return false if procfile.match?(/[;&|`$(){}\[\]<>]/)

          # Ensure it's a readable file
          File.readable?(procfile)
        rescue StandardError
          false
        end
      end
    end
  end
end
