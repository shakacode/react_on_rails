# frozen_string_literal: true

require "open3"
require "socket"

module ReactOnRails
  module Dev
    class FileManager
      # Bounded probe so a stuck server with a full accept queue (rare for a
      # local overmind socket but theoretically possible) cannot stall
      # bin/dev startup indefinitely.
      #
      # Two paths consume this budget differently:
      #   - synchronous failure (typical): UNIX socket connect() to a dead
      #     listener fails in microseconds, so 150 ms is far more than needed.
      #   - async wait_writable: if connect() returns IO::WaitWritable, the
      #     full 150 ms can be consumed waiting for the kernel to mark the
      #     socket writable. This is the actual budget for slow-loopback or
      #     paused-PID cases — not "microseconds".
      # Result: 150 ms is conservative for the common path and the cap for
      # the worst case.
      SOCKET_PROBE_TIMEOUT_SECS = 0.15
      private_constant :SOCKET_PROBE_TIMEOUT_SECS

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

          # Pre-pack the sockaddr in a narrow rescue so the only ArgumentError
          # we swallow is the one Ruby raises for "too long unix socket path"
          # (sun_path is capped at ~104/108 bytes). The wider connect block
          # below intentionally does NOT catch ArgumentError, so a programming
          # mistake in Socket.new or connect_nonblock surfaces instead of
          # silently returning false.
          begin
            sockaddr = Socket.sockaddr_un(socket_path)
          rescue ArgumentError
            return false
          end

          socket = nil
          begin
            socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
            socket.connect_nonblock(sockaddr)
            true
          rescue IO::WaitWritable
            # connect is in progress — wait up to SOCKET_PROBE_TIMEOUT_SECS for
            # writability, then check SO_ERROR to distinguish accepted vs.
            # refused/timed-out connections. Uses socket.wait_writable rather
            # than IO.select so a Fiber scheduler can interleave properly.
            ready = socket.wait_writable(SOCKET_PROBE_TIMEOUT_SECS)
            return false unless ready

            socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR).int.zero?
          rescue Errno::EISCONN
            true
          rescue SystemCallError, IOError
            false
          ensure
            socket&.close
          end
        end

        # Two-stage lookup: try the zero-dependency `/proc/PID/cwd` readlink first
        # (Linux), then fall back to `lsof` (macOS, BSD, Linux without /proc visibility).
        # The /proc path matters for minimal Alpine/CI containers where `lsof`
        # is not installed by default — without it, this method would silently
        # return nil on every container and leave stale PID files behind.
        #
        # The lsof call uses Open3.capture2 with a word-list argv (matching
        # ServerManager#find_port_pids) so the no-shell-injection invariant is
        # structural rather than caller-enforced.
        #
        # Returns nil when both probes fail:
        #   - /proc not present (macOS, BSD) and `lsof` absent (Errno::ENOENT) — minimal containers,
        #   - the kernel withholds info (permission denied, process exited mid-probe),
        #   - any other unexpected error.
        # The nil return causes `cleanup_rails_pid_file` to keep the PID file as a safe
        # fallback. Set DEBUG=1 to surface the failure on stderr.
        def working_directory_for_pid(pid)
          proc_cwd = working_directory_via_proc(pid)
          return proc_cwd if proc_cwd

          working_directory_via_lsof(pid)
        end

        def working_directory_via_proc(pid)
          # File.readlink either returns a non-empty String or raises.
          File.readlink("/proc/#{pid}/cwd")
        rescue Errno::ENOENT, Errno::EACCES, Errno::EPERM, NotImplementedError
          # /proc not present (macOS, BSD), no permission to read this PID's cwd,
          # or readlink unsupported on this platform. Fall through to lsof.
          nil
        end

        def working_directory_via_lsof(pid)
          stdout, = Open3.capture2("lsof", "-a", "-p", pid.to_s, "-d", "cwd", "-Fn", err: File::NULL)
          path_line = stdout.lines.find { |line| line.start_with?("n") }
          path = path_line&.delete_prefix("n")&.strip
          return nil if path.nil? || path.empty?

          path
        rescue Errno::ENOENT => e
          # `lsof` binary missing — expected on minimal images. DEBUG-gated so
          # users on Linux/macOS without the package don't see noise.
          log_lsof_missing(e) if ENV["DEBUG"]
          nil
        rescue StandardError => e
          # Genuinely unexpected: resource limits (Errno::EMFILE), interrupted
          # syscall (Errno::EINTR), permission errors, etc. Always-warn so the
          # cross-directory PID check can't silently misfire under load.
          warn "bin/dev: could not determine working directory for PID #{pid} " \
               "(#{e.class}: #{e.message})."
          nil
        end

        def log_lsof_missing(error)
          warn "bin/dev: `lsof` not found; cross-directory PID check skipped (#{error.message})."
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
