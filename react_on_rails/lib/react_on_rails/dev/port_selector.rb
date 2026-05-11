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
      TCP_PORT_MAX  = 65_535
      MAX_BASE_PORT = TCP_PORT_MAX - BASE_PORT_RENDERER_OFFSET

      # Ports 1..1023 are privileged on Linux/macOS and require root to bind.
      PRIVILEGED_PORT_MAX = 1023

      # Env vars checked (in order) for a base port value.
      #
      # CONDUCTOR_PORT is an empirical interpretation based on Conductor.build
      # (https://conductor.build) allocating a block of consecutive ports per
      # workspace and exposing the block base via this env var. This contract
      # is not in a public Conductor API, so treat CONDUCTOR_PORT support as
      # best-effort until Conductor documents it. If a future release changes
      # the meaning (e.g. CONDUCTOR_PORT becomes the Rails port itself rather
      # than a block base), the derived offsets below will land on the wrong
      # ports — users would see port-conflict failures at runtime rather than
      # a clear misconfiguration error. A future "validate derived ports are
      # reachable on startup" path could surface this earlier.
      #
      # Escape hatch: REACT_ON_RAILS_BASE_PORT takes precedence, so users can
      # override the CONDUCTOR_PORT interpretation without code changes.
      BASE_PORT_ENV_VARS = %w[REACT_ON_RAILS_BASE_PORT CONDUCTOR_PORT].freeze

      class NoPortAvailable < StandardError; end

      class << self
        # Returns { rails: Integer, webpack: Integer, renderer: Integer|nil,
        #           base_port_mode: Boolean }.
        #
        # Priority:
        #   1. Base port (REACT_ON_RAILS_BASE_PORT or CONDUCTOR_PORT) — all ports
        #      derived deterministically from the base; no probing.
        #   2. Explicit per-service env vars (PORT, SHAKAPACKER_DEV_SERVER_PORT).
        #   3. Auto-detect free ports starting from defaults.
        #
        # The :renderer key is populated only when a base port is set (it is a
        # Pro-only service and does not participate in auto-detection).
        # :base_port_mode is true only in case 1.
        #
        # NOTE: This method mutates ENV.
        # @side_effect Deletes invalid PORT / SHAKAPACKER_DEV_SERVER_PORT
        #   values via `read_and_sanitize_port_env!` so ServerManager's
        #   apply_explicit_port_env path doesn't re-warn on the same bad
        #   value. Intended for `bin/dev` startup; do not call from
        #   read-only contexts that expect ENV to survive the call. See
        #   `read_and_sanitize_port_env!` (which uses the `!` suffix to make
        #   the mutation explicit at the inner call site).
        # @param pro_renderer [Boolean] when false, suppresses the renderer
        #   port-in-use warning so OSS apps without a node renderer don't
        #   see "port X (renderer)" noise on a coincidentally-bound base+2.
        def select_ports!(pro_renderer: true)
          base = base_port_ports(pro_renderer: pro_renderer)
          return base if base

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

          { rails: rails_port, webpack: webpack_port, renderer: nil, base_port_mode: false }
        end

        # Deprecated alias for the pre-bang name. Kept as a safety net for any
        # external caller (generator extension, host-app rake task) that wired
        # to `select_ports` before the rename. The bang form is preferred — it
        # surfaces the ENV-mutation side effect at the call site, which was
        # the whole point of the rename. Remove in a future major release.
        def select_ports(**kwargs)
          select_ports!(**kwargs)
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

        # Returns the base-port-derived port hash when a base port env var is
        # set (with the same shape as #select_ports!), otherwise nil. Does not
        # fall back to per-service env vars or auto-detect, so callers can
        # branch on "is base-port mode active?" without triggering probing.
        # Used by ServerManager so all bin/dev modes (development, static,
        # production-like) honor the base-port contract consistently.
        #
        # Logs the detected base port and warns on derived-port collisions.
        # Callers that need the derived ports without user-facing output
        # (e.g. ServerManager#kill_processes, which shouldn't print a banner
        # while killing) should use #base_port_hash instead.
        def base_port_ports(pro_renderer: true)
          bp, source = base_port_with_source
          return nil unless bp

          ports = derive_ports_from_base(bp)
          source_note = if source == "CONDUCTOR_PORT"
                          " (unofficial contract; set REACT_ON_RAILS_BASE_PORT to override)"
                        else
                          ""
                        end
          renderer_segment = pro_renderer ? ", renderer :#{ports[:renderer]}" : ""
          puts "Base port #{bp} detected via #{source}#{source_note}. Using Rails :#{ports[:rails]}, " \
               "webpack :#{ports[:webpack]}#{renderer_segment}"
          warn_if_derived_ports_in_use(bp, ports, source: source, pro_renderer: pro_renderer)
          ports
        end

        # Pure derivation: returns the same port hash as #base_port_ports but
        # without the "Base port X detected" log line or the derived-port
        # collision warnings. Safe to call from any context where logging is
        # undesirable (e.g. kill flows). Still delegates to
        # #base_port_with_source, which surfaces invalid-value warnings — those
        # describe the env input, not the port output, and are desirable even
        # in silent callers.
        def base_port_hash
          bp, _source = base_port_with_source
          return nil unless bp

          derive_ports_from_base(bp)
        end

        def find_available_port(start_port, exclude: nil)
          MAX_ATTEMPTS.times do |i|
            port = start_port + i
            next if port == exclude

            return port if port_available?(port)
          end

          raise NoPortAvailable, "No available port found starting at #{start_port}."
        end

        # Strict port-string predicate shared with ServerManager so the two
        # layers can't silently diverge. `String#to_i` would otherwise truncate
        # `"3000abc"` to 3000 and slip it through here while ServerManager's
        # overwrite path rejected it.
        def valid_port_string?(value)
          return false if value.nil?

          stripped = value.to_s.strip
          return false if stripped.empty?
          return false unless stripped.match?(/\A\d+\z/)

          stripped.to_i.between?(1, TCP_PORT_MAX)
        end

        private

        def derive_ports_from_base(base)
          {
            rails: base + BASE_PORT_RAILS_OFFSET,
            webpack: base + BASE_PORT_WEBPACK_OFFSET,
            renderer: base + BASE_PORT_RENDERER_OFFSET,
            base_port_mode: true
          }
        end

        # Advisory: surface early conflicts when a base port's derived ports are
        # already bound (e.g. two worktrees share a base). Does not fail — the
        # actual bind at server start gives the definitive error.
        #
        # Skips the renderer port when `pro_renderer` is false: OSS apps don't
        # run a node renderer, so "port base+2 (renderer) is already in use"
        # would be confusing noise on a coincidental collision with an
        # unrelated local service.
        #
        # When the base came from CONDUCTOR_PORT and the *Rails* port (base+0)
        # is taken, append a hint that Conductor's contract is unofficial —
        # this is the most likely failure mode if Conductor ever changes
        # CONDUCTOR_PORT to mean "the Rails port" rather than "a block base"
        # (the derived ports would silently land on whatever the user already
        # has bound).
        def warn_if_derived_ports_in_use(base, ports, source: nil, pro_renderer: true)
          roles = pro_renderer ? %i[rails webpack renderer] : %i[rails webpack]
          roles.each do |role|
            port_num = ports[role]
            next if port_available?(port_num)

            hint = if role == :rails && source == "CONDUCTOR_PORT"
                     " If your Conductor workspace exposes CONDUCTOR_PORT as the Rails port " \
                       "rather than a block base, set REACT_ON_RAILS_BASE_PORT explicitly to override."
                   else
                     ""
                   end
            warn "WARNING: port #{port_num} (#{role}, derived from base #{base}) is already in use.#{hint}"
          end
        end

        # Returns [val, source_var] when a valid base port env var is set,
        # otherwise nil. The source var is included so callers can surface it
        # in user-facing log lines (helpful when CONDUCTOR_PORT vs.
        # REACT_ON_RAILS_BASE_PORT activated base-port mode).
        def base_port_with_source
          # Upper bound accounts for the largest derived offset so base + N stays
          # within the valid TCP port range (1..65_535).
          #
          # Strip before validating so whitespace-padded values (common with
          # copy-paste or env-file templating) parse the same way PORT and
          # SHAKAPACKER_DEV_SERVER_PORT do via read_and_sanitize_port_env!.
          BASE_PORT_ENV_VARS.each_with_index do |var, idx|
            raw = ENV.fetch(var, nil)
            next if raw.nil?

            stripped = raw.strip
            next if stripped.empty?

            unless stripped.match?(/\A\d+\z/)
              warn invalid_base_port_warning(var, raw, "not a valid integer", idx)
              next
            end

            val = stripped.to_i
            unless val.between?(1, MAX_BASE_PORT)
              reason = "out of range (1..#{MAX_BASE_PORT}; must leave room for " \
                       "+#{BASE_PORT_RENDERER_OFFSET} renderer offset)"
              warn invalid_base_port_warning(var, raw, reason, idx)
              next
            end

            if val <= PRIVILEGED_PORT_MAX
              warn "WARNING: #{var}=#{raw.inspect} is in the privileged range " \
                   "(1..#{PRIVILEGED_PORT_MAX}); binding will fail without root."
            end

            return [val, var]
          end
          nil
        end

        # Invalid REACT_ON_RAILS_BASE_PORT silently falls through to CONDUCTOR_PORT
        # (or any future later entry). Surface the fallthrough in the warning so
        # users who set a non-integer to "disable" base port mode realize they
        # also need to unset the next var.
        #
        # Filter `remaining` against the same validity rules as `base_port_ports`
        # (numeric + 1..MAX_BASE_PORT) so we never promise activation from a
        # var that the validator will also reject — e.g.
        # `REACT_ON_RAILS_BASE_PORT="disabled"` + `CONDUCTOR_PORT="abc"` must
        # not say "will still activate from CONDUCTOR_PORT".
        def invalid_base_port_warning(var, raw, reason, idx)
          msg = "WARNING: #{var}=#{raw.inspect} is #{reason}; ignoring."
          remaining = BASE_PORT_ENV_VARS[(idx + 1)..].select do |v|
            val = ENV.fetch(v, "").strip
            val.match?(/\A\d+\z/) && val.to_i.between?(1, MAX_BASE_PORT)
          end
          return msg if remaining.empty?

          msg + " Base port mode will still activate from #{remaining.join(', ')}; " \
                "unset to disable entirely."
        end

        def explicit_rails_port
          read_and_sanitize_port_env!("PORT")
        end

        def explicit_webpack_port
          read_and_sanitize_port_env!("SHAKAPACKER_DEV_SERVER_PORT")
        end

        # Reject values that aren't valid port strings and clear the env var
        # so ServerManager's apply_explicit_port_env path (which also rejects
        # them) doesn't emit a second warning for the same value.
        #
        # The `!` suffix signals the ENV-mutation side effect at the call site
        # (explicit_rails_port / explicit_webpack_port); the "warn once + fall
        # back" flow is shared with ServerManager via the cleared env, not via
        # the return value. Kept in one place so the coupling is obvious.
        def read_and_sanitize_port_env!(var_name)
          raw = ENV.fetch(var_name, nil)
          return nil if raw.nil?

          stripped = raw.strip
          return nil if stripped.empty?

          unless stripped.match?(/\A\d+\z/)
            warn "WARNING: #{var_name}=#{raw.inspect} is not a valid integer; ignoring."
            ENV.delete(var_name)
            return nil
          end

          n = stripped.to_i
          unless n.between?(1, TCP_PORT_MAX)
            warn "WARNING: #{var_name}=#{raw.inspect} is out of range (1..#{TCP_PORT_MAX}); ignoring."
            ENV.delete(var_name)
            return nil
          end

          n
        end
      end
    end
  end
end
