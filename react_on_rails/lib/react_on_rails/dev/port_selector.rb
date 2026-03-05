# frozen_string_literal: true

require "socket"

module ReactOnRails
  module Dev
    class PortSelector
      DEFAULT_RAILS_PORT   = 3000
      DEFAULT_WEBPACK_PORT = 3035
      MAX_ATTEMPTS         = 100

      class NoPortAvailable < StandardError; end

      class << self
        # Returns { rails: Integer, webpack: Integer }.
        # Respects existing ENV['PORT'] / ENV['SHAKAPACKER_DEV_SERVER_PORT'].
        # Probes for free ports when either or both env vars are unset.
        def select_ports
          rails_port   = explicit_rails_port
          webpack_port = explicit_webpack_port

          # If both are explicitly set, trust the user completely
          return { rails: rails_port, webpack: webpack_port } if rails_port && webpack_port

          # If only one is set, anchor it and probe for a free port on the other side
          if rails_port
            return { rails: rails_port,
                     webpack: find_available_port(DEFAULT_WEBPACK_PORT, exclude: rails_port) }
          end

          if webpack_port
            return { rails: find_available_port(DEFAULT_RAILS_PORT, exclude: webpack_port),
                     webpack: webpack_port }
          end

          # Neither set — auto-detect a free pair
          find_free_pair
        end

        # Public so it can be stubbed in tests.
        # NOTE: Inherent TOCTOU race — another process can claim the port between
        # server.close and the caller binding to it. This is unavoidable with the
        # probe-then-use pattern and acceptable for the worktree port-selection use case.
        def port_available?(port, host = "127.0.0.1")
          server = TCPServer.new(host, port)
          server.close
          true
        rescue Errno::EADDRINUSE, Errno::EACCES
          false
        end

        private

        def explicit_rails_port
          ENV["PORT"]&.to_i&.then { |p| p.between?(1, 65_535) ? p : nil }
        end

        def explicit_webpack_port
          ENV["SHAKAPACKER_DEV_SERVER_PORT"]&.to_i&.then { |p| p.between?(1, 65_535) ? p : nil }
        end

        def find_available_port(start_port, exclude: nil)
          MAX_ATTEMPTS.times do |i|
            port = start_port + i
            next if port == exclude

            return port if port_available?(port)
          end

          raise NoPortAvailable, "No available port found starting at #{start_port}."
        end

        def find_free_pair
          rails_port   = find_available_port(DEFAULT_RAILS_PORT)
          webpack_port = find_available_port(DEFAULT_WEBPACK_PORT, exclude: rails_port)

          if rails_port != DEFAULT_RAILS_PORT || webpack_port != DEFAULT_WEBPACK_PORT
            puts "Default ports in use. Using Rails :#{rails_port}, webpack :#{webpack_port}"
          end

          { rails: rails_port, webpack: webpack_port }
        end
      end
    end
  end
end
