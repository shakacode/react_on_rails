# frozen_string_literal: true

module ReactOnRails
  module Dev
    class ProcessManager
      class << self
        def installed?(process)
          IO.popen([process, "-v"], &:close)
          true
        rescue Errno::ENOENT
          false
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

          if installed?("overmind")
            system("overmind", "start", "-f", procfile)
          elsif foreman_available?
            run_foreman(procfile)
          else
            show_process_manager_installation_help
            exit 1
          end
        end

        private

        # Check if foreman is available in either bundler context or system-wide
        def foreman_available?
          installed?("foreman") || foreman_available_in_system?
        end

        # Try to run foreman with intelligent fallback strategy
        # First attempt: within bundler context (for projects that include foreman in Gemfile)
        # Fallback: outside bundler context (for projects following React on Rails best practices)
        def run_foreman(procfile)
          success = if installed?("foreman")
                      # Try within bundle context first
                      system("foreman", "start", "-f", procfile)
                    else
                      false
                    end

          # If bundler context failed or foreman not in bundle, try system foreman
          return if success

          run_foreman_outside_bundle(procfile)
        end

        # Run foreman outside of bundler context using Bundler.with_unbundled_env
        # This allows using system-installed foreman even when it's not in the Gemfile
        def run_foreman_outside_bundle(procfile)
          if defined?(Bundler)
            Bundler.with_unbundled_env do
              system("foreman", "start", "-f", procfile)
            end
          else
            # Fallback if Bundler is not available
            system("foreman", "start", "-f", procfile)
          end
        end

        # Check if foreman is available system-wide (outside bundle context)
        def foreman_available_in_system?
          if defined?(Bundler)
            Bundler.with_unbundled_env do
              installed?("foreman")
            end
          else
            false
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
