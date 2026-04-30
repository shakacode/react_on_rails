# frozen_string_literal: true

require "open3"
require "socket"

module ReactOnRails
  module Dev
    class FileManager
      class << self
        def cleanup_stale_files
          socket_cleanup = cleanup_overmind_sockets
          pid_cleanup = cleanup_rails_pid_file

          socket_cleanup || pid_cleanup
        end

        private

        # Targets overmind-named sockets only (`.overmind.sock` at the project root and
        # `tmp/sockets/overmind*.sock` for copied/renamed variants). Inactive matches are
        # removed on startup. Other apps' Unix sockets in `tmp/sockets/` (Puma, Action
        # Cable, custom services) are left untouched even when stale, so a tight
        # startup race window cannot delete a socket bin/dev does not own.
        def cleanup_overmind_sockets
          socket_files = [".overmind.sock", *Dir.glob("tmp/sockets/overmind*.sock")].uniq
          cleaned_any = false

          socket_files.each do |socket_file|
            next if socket_active?(socket_file)

            cleaned_any = true if remove_file_if_exists(socket_file, "stale socket")
          end

          cleaned_any
        end

        def cleanup_rails_pid_file
          server_pid_file = "tmp/pids/server.pid"
          return false unless File.exist?(server_pid_file)

          pid_content = File.read(server_pid_file).strip
          begin
            pid = Integer(pid_content)
            # PIDs must be > 1 (0 is kernel, 1 is init)
            if pid <= 1
              remove_file_if_exists(server_pid_file, "stale Rails pid file")
              return true
            end
          rescue ArgumentError, TypeError
            remove_file_if_exists(server_pid_file, "stale Rails pid file")
            return true
          end

          unless process_running?(pid)
            remove_file_if_exists(server_pid_file, "stale Rails pid file")
            return true
          end

          pid_working_directory = working_directory_for_pid(pid)
          return false if pid_working_directory.nil? || same_working_directory?(pid_working_directory, Dir.pwd)

          remove_file_if_exists(server_pid_file, "stale Rails pid file from another app directory")
        end

        def process_running?(pid)
          Process.kill(0, pid)
          true
        rescue Errno::ESRCH, ArgumentError, RangeError
          # Process doesn't exist or invalid PID
          false
        rescue Errno::EPERM
          # Process exists but we don't have permission to signal it
          true
        end

        def socket_active?(socket_path)
          return false unless File.exist?(socket_path)

          UNIXSocket.open(socket_path, &:close)
          true
        rescue IOError, SystemCallError
          false
        end

        # Uses Open3.capture2 with a word-list argv (matching ServerManager#find_port_pids)
        # so the no-shell-injection invariant is structural rather than caller-enforced —
        # passing a non-Integer pid in the future cannot introduce a shell metacharacter.
        #
        # Returns nil when:
        #   - `lsof` is absent (Errno::ENOENT) — common on minimal Alpine/CI images,
        #   - `lsof` runs but produces no `n` line (process exited or kernel withholds info),
        #   - any other unexpected error.
        # The nil return causes `cleanup_rails_pid_file` to keep the PID file as a safe
        # fallback. The "lsof not found" branch silently skips the cross-directory check;
        # set DEBUG=1 to surface the cause on stderr.
        def working_directory_for_pid(pid)
          stdout, = Open3.capture2("lsof", "-a", "-p", pid.to_s, "-d", "cwd", "-Fn", err: File::NULL)
          path_line = stdout.lines.find { |line| line.start_with?("n") }
          path = path_line&.delete_prefix("n")&.strip
          return nil if path.nil? || path.empty?

          path
        rescue StandardError => e
          log_lsof_error(pid, e)
          nil
        end

        def log_lsof_error(pid, error)
          return unless ENV["DEBUG"]

          if error.is_a?(Errno::ENOENT)
            warn "bin/dev: `lsof` not found; cross-directory PID check skipped (#{error.message})."
          else
            warn "bin/dev: could not determine working directory for PID #{pid} " \
                 "(#{error.class}: #{error.message})."
          end
        end

        def same_working_directory?(left, right)
          File.realpath(left) == File.realpath(right)
        rescue SystemCallError
          File.expand_path(left) == File.expand_path(right)
        end

        def remove_file_if_exists(file_path, description)
          return false unless File.exist?(file_path)

          puts "   🧹 Cleaning up #{description}: #{file_path}"
          File.delete(file_path)
          true
        rescue StandardError
          false
        end
      end
    end
  end
end
