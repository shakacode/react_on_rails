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
          elsif installed?("foreman")
            system("foreman", "start", "-f", procfile)
          else
            warn <<~MSG
              NOTICE:
              For this script to run, you need either 'overmind' or 'foreman' installed on your machine. Please try this script after installing one of them.
            MSG
            exit 1
          end
        end

        private

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
