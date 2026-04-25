# frozen_string_literal: true

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

        def cleanup_overmind_sockets
          socket_files = [".overmind.sock", "tmp/sockets/overmind.sock", *Dir.glob("tmp/sockets/*.sock")].uniq
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

        def working_directory_for_pid(pid)
          path_line = `lsof -a -p #{pid} -d cwd -Fn 2>/dev/null`.lines.find { |line| line.start_with?("n") }
          path = path_line&.delete_prefix("n")&.strip
          return nil if path.nil? || path.empty?

          path
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
