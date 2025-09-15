# frozen_string_literal: true

module ReactOnRails
  module Dev
    class FileManager
      class << self
        def cleanup_stale_files
          cleaned_any = false

          # Check for stale overmind socket files
          socket_files = [".overmind.sock", "tmp/sockets/overmind.sock"]

          # Only clean up if overmind is not actually running
          overmind_pids = `pgrep -f "overmind" 2>/dev/null`.split("\n").map(&:to_i)

          if overmind_pids.empty?
            socket_files.each do |socket_file|
              next unless File.exist?(socket_file)

              puts "   🧹 Cleaning up stale socket: #{socket_file}"
              begin
                File.delete(socket_file)
              rescue StandardError
                nil
              end
              cleaned_any = true
            end
          end

          # Check for stale Rails server.pid file
          server_pid_file = "tmp/pids/server.pid"
          if File.exist?(server_pid_file)
            pid = File.read(server_pid_file).to_i
            # Check if process is actually running
            begin
              Process.kill(0, pid)
              # Process exists, don't clean up
            rescue Errno::ESRCH
              # Process doesn't exist, clean up stale pid file
              puts "   🧹 Cleaning up stale Rails pid file: #{server_pid_file}"
              begin
                File.delete(server_pid_file)
              rescue StandardError
                nil
              end
              cleaned_any = true
            end
          end

          cleaned_any
        end
      end
    end
  end
end
