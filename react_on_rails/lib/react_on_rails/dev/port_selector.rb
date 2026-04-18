# frozen_string_literal: true

require "socket"

module ReactOnRails
  module Dev
    class PortSelector
      DEFAULT_RAILS_PORT   = 3000
      DEFAULT_WEBPACK_PORT = 3035
      MAX_ATTEMPTS         = 100

      # Offsets from the base port when REACT_ON_RAILS_BASE_PORT (or a recognized
      # tool-specific equivalent like CONDUCTOR_PORT) is set. The base port block
      # is typically 10 consecutive ports allocated per workspace.
      BASE_PORT_RAILS_OFFSET    = 0
      BASE_PORT_WEBPACK_OFFSET  = 1
      BASE_PORT_RENDERER_OFFSET = 2
      MAX_BASE_PORT = 65_535 - BASE_PORT_RENDERER_OFFSET

      # Env vars checked (in order) for a base port value.
      BASE_PORT_ENV_VARS = %w[REACT_ON_RAILS_BASE_PORT CONDUCTOR_PORT].freeze

      class NoPortAvailable < StandardError; end

      class << self
        # Returns { rails: Integer, webpack: Integer, renderer: Integer|nil }.
        #
        # Priority:
        #   1. Base port (REACT_ON_RAILS_BASE_PORT or CONDUCTOR_PORT) — all ports
        #      derived deterministically from the base; no probing.
        #   2. Explicit per-service env vars (PORT, SHAKAPACKER_DEV_SERVER_PORT).
        #   3. Auto-detect free ports starting from defaults.
        #
        # The :renderer key is populated only when a base port is set (it is a
        # Pro-only service and does not participate in auto-detection).
        def select_ports
          bp = base_port
          if bp
            ports = {
              rails: bp + BASE_PORT_RAILS_OFFSET,
              webpack: bp + BASE_PORT_WEBPACK_OFFSET,
              renderer: bp + BASE_PORT_RENDERER_OFFSET
            }
            puts "Base port #{bp} detected. Using Rails :#{ports[:rails]}, " \
                 "webpack :#{ports[:webpack]}, renderer :#{ports[:renderer]}"
            return ports
          end

          rails_port   = explicit_rails_port
          webpack_port = explicit_webpack_port

          rails_auto   = rails_port.nil?
          webpack_auto = webpack_port.nil?

          rails_port   ||= find_available_port(DEFAULT_RAILS_PORT, exclude: webpack_port)
          webpack_port ||= find_available_port(DEFAULT_WEBPACK_PORT, exclude: rails_port)

          if (rails_auto && rails_port != DEFAULT_RAILS_PORT) ||
             (webpack_auto && webpack_port != DEFAULT_WEBPACK_PORT)
            puts "Default ports in use. Using Rails :#{rails_port}, webpack :#{webpack_port}"
          end

          { rails: rails_port, webpack: webpack_port, renderer: nil }
        end

        # Public so it can be stubbed in tests.
        # NOTE: Inherent TOCTOU race — another process can claim the port between
        # server.close and the caller binding to it. This is unavoidable with the
        # probe-then-use pattern and acceptable for the worktree port-selection use case.
        def port_available?(port)
          # Check both IPv4 and IPv6 loopback. Node 22+ resolves "localhost"
          # to ::1 first, so webpack-dev-server often binds only to IPv6.
          # A pure-IPv4 probe would miss that listener.
          %w[127.0.0.1 ::1].all? do |host|
            server = TCPServer.new(host, port)
            server.close
            true
          rescue Errno::EADDRINUSE, Errno::EACCES
            false
          rescue Errno::EADDRNOTAVAIL, SocketError
            true # address family unavailable on this system
          end
        end

        def find_available_port(start_port, exclude: nil)
          MAX_ATTEMPTS.times do |i|
            port = start_port + i
            next if port == exclude

            return port if port_available?(port)
          end

          raise NoPortAvailable, "No available port found starting at #{start_port}."
        end

        private

        def base_port
          # Upper bound accounts for the largest derived offset so base + N stays
          # within the valid TCP port range (1..65_535).
          BASE_PORT_ENV_VARS.each do |var|
            raw = ENV.fetch(var, nil)
            next if raw.nil? || raw.empty?

            unless raw.match?(/\A\d+\z/)
              warn "WARNING: #{var}=#{raw.inspect} is not a valid integer; ignoring."
              next
            end

            val = raw.to_i
            return val if val.between?(1, MAX_BASE_PORT)
          end
          nil
        end

        def explicit_rails_port
          ENV["PORT"]&.to_i&.then { |p| p.between?(1, 65_535) ? p : nil }
        end

        def explicit_webpack_port
          ENV["SHAKAPACKER_DEV_SERVER_PORT"]&.to_i&.then { |p| p.between?(1, 65_535) ? p : nil }
        end
      end
    end
  end
end
