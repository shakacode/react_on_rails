# frozen_string_literal: true

module ReactOnRails
  module Dev
    class ProcessManager
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

          if process_available?("overmind")
            run_process("overmind", ["start", "-f", procfile])
          elsif process_available?("foreman")
            run_process("foreman", ["start", "-f", procfile])
          else
            show_process_manager_installation_help
            exit 1
          end
        end

        private

        # Check if a process is actually usable in the current execution context
        # This is important for commands that might be intercepted by bundler
        def installed_in_current_context?(process)
          # Try to execute the process with a simple flag to see if it works
          # Use system() because that's how we'll actually call it later
          system(process, "--version", out: File::NULL, err: File::NULL)
        rescue Errno::ENOENT
          false
        end

        # Check if a process is available in either current context or system-wide
        def process_available?(process)
          installed?(process) || process_available_in_system?(process)
        end

        # Try to run a process with intelligent fallback strategy
        # First attempt: within current context (for processes that are in the current bundle)
        # Fallback: outside bundler context (for system-installed processes)
        def run_process(process, args)
          success = if installed?(process)
                      # Process works in current context - use it directly
                      system(process, *args)
                    else
                      false
                    end

          # If current context failed or process not available, try system process
          return if success

          run_process_outside_bundle(process, args)
        end

        # Run a process outside of bundler context using Bundler.with_unbundled_env
        # This allows using system-installed processes even when they're not in the Gemfile
        def run_process_outside_bundle(process, args)
          if defined?(Bundler)
            Bundler.with_unbundled_env do
              system(process, *args)
            end
          else
            # Fallback if Bundler is not available
            system(process, *args)
          end
        end

        # Check if a process is available system-wide (outside bundle context)
        def process_available_in_system?(process)
          if defined?(Bundler)
            Bundler.with_unbundled_env do
              # Use system() directly to check if process exists outside bundler context
              system(process, "--version", out: File::NULL, err: File::NULL)
            end
          else
            false
          end
        rescue Errno::ENOENT
          false
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
            https://github.com/shakacode/react_on_rails/blob/master/docs/javascript/foreman-issues.md

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
