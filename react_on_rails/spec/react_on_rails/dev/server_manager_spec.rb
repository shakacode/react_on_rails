# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/server_manager"
require "open3"
require "stringio"

RSpec.describe ReactOnRails::Dev::ServerManager do
  # Suppress stdout/stderr during tests
  before(:all) do
    @original_stderr = $stderr
    @original_stdout = $stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after(:all) do
    $stderr = @original_stderr
    $stdout = @original_stdout
  end

  shared_context "with clean port env" do
    around do |example|
      old = {}
      # REACT_ON_RAILS_BASE_PORT and CONDUCTOR_PORT must be cleared too: if either
      # is set in the developer's shell (common inside a Conductor workspace),
      # the real PortSelector.select_ports! enters base-port mode, and any test
      # that doesn't stub select_ports! will see unexpected port assignments.
      # Mirrors port_selector_spec.rb's outer `around`.
      %w[PORT SHAKAPACKER_DEV_SERVER_PORT RENDERER_PORT REACT_RENDERER_URL
         RENDERER_URL REACT_ON_RAILS_BASE_PORT CONDUCTOR_PORT].each do |k|
        old[k] = ENV.fetch(k, nil)
        ENV.delete(k)
      end
      example.run
    ensure
      # `old` is assigned on the first line of the block and cannot fail, but
      # guard with `&.` so the ensure stays correct (and CodeQL-clean) if a
      # future change moves the assignment below something that can raise.
      old&.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    end
  end

  def mock_system_calls
    mock_process_managers
    mock_port_selector_defaults
    # Default to "Pro renderer active" so legacy base-port tests that expect
    # RENDERER_PORT / REACT_RENDERER_URL to be set still pass without each
    # context having to pre-set a renderer env var. The OSS guard is exercised
    # in a dedicated context below.
    allow(described_class).to receive(:pro_renderer_active?).and_return(true)
  end

  def mock_process_managers
    allow(ReactOnRails::Dev::PackGenerator).to receive(:generate).with(any_args)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager)
    allow(ReactOnRails::Dev::DatabaseChecker).to receive(:check_database).and_return(true)
  end

  def mock_port_selector_defaults
    # Default to "no base port active" so a developer running specs inside a
    # Conductor workspace (REACT_ON_RAILS_BASE_PORT set in their shell) doesn't
    # silently redirect tests into the base-port branch. Individual contexts
    # that exercise base-port mode override these stubs.
    allow(ReactOnRails::Dev::PortSelector).to receive_messages(
      base_port_ports: nil,
      select_ports!: { rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false }
    )
    allow(ReactOnRails::Dev::PortSelector).to receive(:find_available_port) { |start_port| start_port }
  end

  def capture_stdout
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output
    yield
    output.string
  ensure
    $stdout = original_stdout
  end

  describe ".start" do
    before { mock_system_calls }

    around do |example|
      original_port = ENV.fetch("PORT", nil)
      ENV.delete("PORT")
      example.run
    ensure
      if original_port.nil?
        ENV.delete("PORT")
      else
        ENV["PORT"] = original_port
      end
    end

    it "starts development mode by default" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:development)
    end

    it "sets default PORT=3000 for development mode" do
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev") do
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      described_class.start(:development)
    end

    it "starts HMR mode same as development" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:hmr)
    end

    it "starts static development mode" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-static-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-static-assets")

      described_class.start(:static)
    end

    it "schedules a one-time browser open when requested" do
      expect(described_class).to receive(:schedule_browser_open).with(3000, route: "/", once: true, explicit: false)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:development, nil, route: "/", open_browser_once: true)
    end

    it "schedules an explicit browser open when --open-browser is passed" do
      expect(described_class).to receive(:schedule_browser_open).with(3000, route: "/", once: false, explicit: true)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:development, nil, route: "/", open_browser: true)
    end

    it "starts production-like mode" do
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like)
    end

    it "passes procfile_port to print_server_info in production-like mode" do
      ENV["PORT"] = "4000"
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])

      port_at_server_info_time = nil
      allow(described_class).to receive(:print_server_info).and_wrap_original do |m, *args, **kwargs|
        port_at_server_info_time = args[2]
        m.call(*args, **kwargs)
      end

      described_class.start(:production_like)

      expect(port_at_server_info_time).to eq(4000)
    ensure
      ENV.delete("PORT")
    end

    it "normalizes an invalid PORT to an auto-selected port in production-like mode" do
      ENV["PORT"] = "abc"
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      allow(ReactOnRails::Dev::PortSelector).to receive(:find_available_port).with(3001).and_return(3005)
      expect(ReactOnRails::Dev::ProcessManager)
        .to receive(:run_with_process_manager).with("Procfile.dev-prod-assets") do
          expect(ENV.fetch("PORT", nil)).to eq("3005")
        end

      expect { described_class.start(:production_like) }
        .to output(/PORT=.*not a valid port/).to_stderr
    ensure
      ENV.delete("PORT")
    end

    it "sets default PORT=3001 for production-like mode" do
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager)
        .to receive(:run_with_process_manager).with("Procfile.dev-prod-assets") do
          expect(ENV.fetch("PORT", nil)).to eq("3001")
        end

      described_class.start(:production_like)
    end

    it "does not override an existing PORT value" do
      ENV["PORT"] = "4242"
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev") do
        expect(ENV.fetch("PORT", nil)).to eq("4242")
      end

      described_class.start(:development)
    end

    it "starts production-like mode with custom rails_env" do
      env = { "NODE_ENV" => "production", "RAILS_ENV" => "staging" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like, nil, verbose: false, rails_env: "staging")
    end

    it "prints the bundler compilation hint for rspack precompile errors" do
      allow(described_class).to receive(:configured_assets_bundler).and_return("rspack")
      allow(ReactOnRails::Dev::ServiceChecker).to receive(:check_services).and_return(true)
      allow(ReactOnRails::Dev::PortSelector).to receive(:find_available_port).with(3001).and_return(3001)
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: false)
      expect(Open3).to receive(:capture3)
        .with(env, *argv)
        .and_return(["", "Rspack build failed", status_double])

      expect { described_class.start(:production_like) }
        .to output(%r{Rspack compilation:.*Check JavaScript/rspack errors above}m).to_stdout_from_any_process
    end

    it "rejects invalid rails_env with shell injection characters" do
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      allow_any_instance_of(Kernel).to receive(:puts) # Allow other puts calls
      error_pattern = /Invalid rails_env.*Must contain only letters, numbers, and underscores/
      expect_any_instance_of(Kernel).to receive(:puts).with(error_pattern)

      described_class.start(:production_like, nil, verbose: false, rails_env: "production; rm -rf /")
    end

    it "raises error for unknown mode" do
      expect { described_class.start(:unknown) }.to raise_error(ArgumentError, "Unknown mode: unknown")
    end

    context "when REACT_ON_RAILS_BASE_PORT is set in production-like mode" do
      include_context "with clean port env"

      before do
        # production-like mode does not call configure_ports directly, so stub
        # the base-port accessor to simulate an active base port without
        # touching PortSelector internals. The non-base-port branch still runs
        # sync_renderer_port_and_url for RENDERER_PORT auto-derivation (see the
        # separate context below).
        allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_ports)
          .and_return({ rails: 4000, webpack: 4001, renderer: 4002, base_port_mode: true })
        status_double = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(["output", "", status_double])
      end

      it "derives PORT from the base port instead of the 3001 default" do
        described_class.start(:production_like)
        expect(ENV.fetch("PORT", nil)).to eq("4000")
      end

      it "applies SHAKAPACKER_DEV_SERVER_PORT from base+1 even though prod mode doesn't use webpack-dev-server" do
        # Intentional, not a bug: prod mode runs static assets and does not use
        # webpack-dev-server, but applying all three env vars keeps prod mode
        # consistent with dev/static so any tooling that reads them (shell aliases,
        # process inspectors, a subsequent `bin/dev` in the same shell) sees the
        # same derived values regardless of which bin/dev mode is active. See
        # the matching comment above #apply_base_port_env in server_manager.rb.
        described_class.start(:production_like)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("4001")
      end

      it "applies RENDERER_PORT from base+2" do
        described_class.start(:production_like)
        expect(ENV.fetch("RENDERER_PORT", nil)).to eq("4002")
      end

      it "applies the derived REACT_RENDERER_URL" do
        described_class.start(:production_like)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:4002")
      end

      it "does not fall through to find_available_port(3001) when base port is active" do
        expect(ReactOnRails::Dev::PortSelector).not_to receive(:find_available_port)
        described_class.start(:production_like)
      end

      it "overrides a pre-set PORT=3001 with the base-derived value" do
        # Mirrors the dev-mode contract: base port > explicit per-service env vars.
        ENV["PORT"] = "3001"
        described_class.start(:production_like)
        expect(ENV.fetch("PORT", nil)).to eq("4000")
      end
    end

    context "when CONDUCTOR_PORT is set in production-like mode (no REACT_ON_RAILS_BASE_PORT)" do
      include_context "with clean port env"

      before do
        allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_ports)
          .and_return({ rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true })
        status_double = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(["output", "", status_double])
      end

      it "honors the base port just like REACT_ON_RAILS_BASE_PORT" do
        described_class.start(:production_like)
        expect(ENV.fetch("PORT", nil)).to eq("5000")
      end
    end

    # `bin/dev prod` used to skip `sync_renderer_port_and_url` — dev and static
    # modes auto-derived REACT_RENDERER_URL from a bare RENDERER_PORT and
    # warned on mismatches, but prod-like mode did not. These specs lock in
    # the new parity: without base port mode, production-like now runs the
    # same renderer env sync that `bin/dev` and `bin/dev static` do.
    context "when production-like mode runs without base port" do
      include_context "with clean port env"

      before do
        allow(ReactOnRails::Dev::PortSelector).to receive_messages(base_port_ports: nil, find_available_port: 3001)
        status_double = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(["output", "", status_double])
      end

      it "auto-derives REACT_RENDERER_URL from a bare RENDERER_PORT" do
        ENV["RENDERER_PORT"] = "3800"
        described_class.start(:production_like)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:3800")
      end

      it "warns when RENDERER_PORT and REACT_RENDERER_URL disagree" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://localhost:3800"
        expect { described_class.start(:production_like) }
          .to output(%r{RENDERER_PORT=3801 does not match REACT_RENDERER_URL=http://localhost:3800}).to_stderr
      end
    end

    context "when running production-like mode without a base port" do
      include_context "with clean port env"

      before do
        allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_ports).and_return(nil)
        status_double = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(["output", "", status_double])
      end

      it "still uses the 3001 prod-specific default when no base port is set" do
        described_class.start(:production_like)
        expect(ENV.fetch("PORT", nil)).to eq("3001")
      end

      it "still respects a pre-set valid PORT when no base port is set" do
        # Preserves the existing "PORT is sticky" behavior so users who pin a
        # specific prod-assets port in their env aren't surprised by the
        # base-port change.
        ENV["PORT"] = "4242"
        described_class.start(:production_like)
        expect(ENV.fetch("PORT", nil)).to eq("4242")
      end

      it "exits cleanly when find_available_port raises NoPortAvailable" do
        # Mirrors the existing rescue in `configure_ports`. Without the rescue
        # in `run_production_like`, an exhausted port range produced an
        # unhandled Ruby backtrace instead of a one-line warning.
        allow(ReactOnRails::Dev::PortSelector).to receive(:find_available_port)
          .and_raise(ReactOnRails::Dev::PortSelector::NoPortAvailable, "No port found")
        ENV["PORT"] = "abc"
        expect_any_instance_of(Kernel).to receive(:exit).with(1)
        expect { described_class.start(:production_like) }.to output(/No port found/).to_stderr
      end
    end

    context "when configuring ports" do
      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      around do |example|
        old_port = ENV.fetch("PORT", nil)
        old_webpack_port = ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)
        ENV.delete("PORT")
        ENV.delete("SHAKAPACKER_DEV_SERVER_PORT")
        example.run
      ensure
        ENV["PORT"] = old_port
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = old_webpack_port
      end

      it "sets PORT env var before starting development mode" do
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      it "sets SHAKAPACKER_DEV_SERVER_PORT env var before starting development mode" do
        described_class.start(:development)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("3035")
      end

      it "sets PORT env var before starting static mode" do
        described_class.start(:static)
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      it "uses auto-detected ports when defaults are occupied" do
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3001, webpack: 3036, renderer: nil, base_port_mode: false })
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("3001")
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("3036")
      end

      it "has PORT set when print_procfile_info is called in development mode" do
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3001, webpack: 3036, renderer: nil, base_port_mode: false })

        port_at_print_time = nil
        allow(described_class).to receive(:print_procfile_info).and_wrap_original do |m, *args, **kwargs|
          port_at_print_time = ENV.fetch("PORT", nil)
          m.call(*args, **kwargs)
        end

        described_class.start(:development)

        expect(port_at_print_time).to eq("3001")
      end

      it "passes the auto-detected port to print_server_info in static mode" do
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3001, webpack: 3036, renderer: nil, base_port_mode: false })

        port_at_server_info_time = nil
        allow(described_class).to receive(:print_server_info).and_wrap_original do |m, *args, **kwargs|
          port_at_server_info_time = args[2]
          m.call(*args, **kwargs)
        end

        described_class.start(:static)

        expect(port_at_server_info_time).to eq(3001)
      end

      it "has PORT set when print_procfile_info is called in static mode" do
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3001, webpack: 3036, renderer: nil, base_port_mode: false })

        port_at_print_time = nil
        allow(described_class).to receive(:print_procfile_info).and_wrap_original do |m, *args, **kwargs|
          port_at_print_time = ENV.fetch("PORT", nil)
          m.call(*args, **kwargs)
        end

        described_class.start(:static)

        expect(port_at_print_time).to eq("3001")
      end

      it "exits cleanly when no port pair is available" do
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_raise(ReactOnRails::Dev::PortSelector::NoPortAvailable, "No available port pair found")

        expect_any_instance_of(Kernel).to receive(:exit).with(1)
        expect { described_class.start(:development) }.not_to raise_error
      end
    end

    context "when configuring ports with a base port active" do
      include_context "with clean port env"

      before do
        mock_system_calls
        # configure_ports calls select_ports! once; select_ports! internally
        # consults base_port_ports and returns that hash when base-port mode
        # is active. Stub both so every code path (select_ports! callers and
        # direct base_port_ports callers like run_production_like) sees the
        # same base-port result.
        base_port_hash = { rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true }
        allow(ReactOnRails::Dev::PortSelector).to receive_messages(
          base_port_ports: base_port_hash,
          select_ports!: base_port_hash
        )
      end

      it "overrides a pre-existing PORT with the base-derived Rails port" do
        ENV["PORT"] = "3000"
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("5000")
      end

      it "overrides a pre-existing SHAKAPACKER_DEV_SERVER_PORT with the base-derived webpack port" do
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "3035"
        described_class.start(:development)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("5001")
      end

      it "overrides pre-existing RENDERER_PORT and REACT_RENDERER_URL with base-derived values" do
        ENV["RENDERER_PORT"] = "3800"
        ENV["REACT_RENDERER_URL"] = "http://localhost:3800"
        described_class.start(:development)
        expect(ENV.fetch("RENDERER_PORT", nil)).to eq("5002")
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:5002")
      end

      it "warns before overriding a non-localhost REACT_RENDERER_URL" do
        ENV["REACT_RENDERER_URL"] = "http://renderer.internal:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding REACT_RENDERER_URL="http://renderer.internal:3800"}).to_stderr
      end

      it "rewrites a remote REACT_RENDERER_URL to the standard localhost derived URL" do
        ENV["REACT_RENDERER_URL"] = "http://renderer.internal:3800"
        described_class.start(:development)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:5002")
      end

      it "warns before overriding a localhost REACT_RENDERER_URL on a different port" do
        ENV["REACT_RENDERER_URL"] = "http://localhost:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding REACT_RENDERER_URL="http://localhost:3800" with http://localhost:5002}).to_stderr
      end

      it "preserves an explicit IPv4 localhost REACT_RENDERER_URL host in base-port mode" do
        ENV["REACT_RENDERER_URL"] = "http://127.0.0.1:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding REACT_RENDERER_URL="http://127.0.0.1:3800" with http://127.0.0.1:5002})
          .to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://127.0.0.1:5002")
      end

      it "preserves an explicit IPv6 localhost REACT_RENDERER_URL host in base-port mode" do
        ENV["REACT_RENDERER_URL"] = "http://[::1]:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding REACT_RENDERER_URL="http://\[::1\]:3800" with http://\[::1\]:5002})
          .to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://[::1]:5002")
      end

      it "warns before overriding an HTTPS localhost REACT_RENDERER_URL on a different port" do
        ENV["REACT_RENDERER_URL"] = "https://localhost:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding REACT_RENDERER_URL="https://localhost:3800"}).to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("https://localhost:5002")
      end

      it "does not warn when REACT_RENDERER_URL already equals the derived URL" do
        ENV["REACT_RENDERER_URL"] = "http://localhost:5002"
        expect { described_class.start(:development) }
          .not_to output(/Overriding REACT_RENDERER_URL/).to_stderr
      end

      it "rewrites a legacy RENDERER_URL to the derived URL" do
        ENV["RENDERER_URL"] = "http://localhost:3800"
        described_class.start(:development)
        expect(ENV.fetch("RENDERER_URL", nil)).to eq("http://localhost:5002")
      end

      it "preserves a legacy localhost-equivalent RENDERER_URL host when REACT_RENDERER_URL is unset" do
        ENV["RENDERER_URL"] = "http://127.0.0.1:3800"
        described_class.start(:development)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://127.0.0.1:5002")
        expect(ENV.fetch("RENDERER_URL", nil)).to eq("http://127.0.0.1:5002")
      end

      it "warns before overriding a legacy RENDERER_URL on a different port" do
        ENV["RENDERER_URL"] = "http://localhost:3800"
        expect { described_class.start(:development) }
          .to output(%r{Overriding RENDERER_URL="http://localhost:3800" with http://localhost:5002}).to_stderr
      end

      it "does not introduce RENDERER_URL when it is unset" do
        described_class.start(:development)
        expect(ENV).not_to have_key("RENDERER_URL")
      end

      it "does not warn when RENDERER_URL already equals the derived URL" do
        ENV["RENDERER_URL"] = "http://localhost:5002"
        expect { described_class.start(:development) }
          .not_to output(/Overriding RENDERER_URL/).to_stderr
      end

      it "warns before overriding a pre-existing PORT" do
        ENV["PORT"] = "3000"
        expect { described_class.start(:development) }
          .to output(/Overriding PORT="3000" with 5000/).to_stderr
      end

      it "warns before overriding a pre-existing SHAKAPACKER_DEV_SERVER_PORT" do
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "3035"
        expect { described_class.start(:development) }
          .to output(/Overriding SHAKAPACKER_DEV_SERVER_PORT="3035" with 5001/).to_stderr
      end

      it "warns before overriding a pre-existing RENDERER_PORT" do
        ENV["RENDERER_PORT"] = "3800"
        expect { described_class.start(:development) }
          .to output(/Overriding RENDERER_PORT="3800" with 5002/).to_stderr
      end

      it "does not warn when PORT is unset" do
        expect { described_class.start(:development) }
          .not_to output(/Overriding PORT/).to_stderr
      end

      it "does not warn when PORT already matches the derived value" do
        ENV["PORT"] = "5000"
        expect { described_class.start(:development) }
          .not_to output(/Overriding PORT/).to_stderr
      end

      it "does not warn when PORT matches the derived value with surrounding whitespace" do
        ENV["PORT"] = " 5000 "
        expect { described_class.start(:development) }
          .not_to output(/Overriding PORT/).to_stderr
      end

      it "does not warn when RENDERER_PORT already matches the derived value" do
        ENV["RENDERER_PORT"] = "5002"
        expect { described_class.start(:development) }
          .not_to output(/Overriding RENDERER_PORT/).to_stderr
      end

      it "applies the base-derived PORT in static mode" do
        # Both run_static_development and run_development call configure_ports,
        # so the base-port behavior should be identical across modes. This
        # locks in :static so a future refactor that drops configure_ports
        # from run_static_development gets caught.
        described_class.start(:static)
        expect(ENV.fetch("PORT", nil)).to eq("5000")
      end

      it "applies the base-derived SHAKAPACKER_DEV_SERVER_PORT in static mode" do
        described_class.start(:static)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("5001")
      end

      it "applies the base-derived RENDERER_PORT in static mode" do
        described_class.start(:static)
        expect(ENV.fetch("RENDERER_PORT", nil)).to eq("5002")
      end
    end

    context "when base port mode is active in an OSS-only environment" do
      include_context "with clean port env"

      before do
        mock_system_calls
        # Disable the default Pro stub so the OSS guard runs for real.
        allow(described_class).to receive(:pro_renderer_active?).and_call_original
        allow(Gem.loaded_specs).to receive(:key?).and_call_original
        allow(Gem.loaded_specs).to receive(:key?).with("react_on_rails_pro").and_return(false)
        base_port_hash = { rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true }
        allow(ReactOnRails::Dev::PortSelector).to receive_messages(
          base_port_ports: base_port_hash,
          select_ports!: base_port_hash
        )
      end

      it "still applies the base-derived PORT" do
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("5000")
      end

      it "still applies the base-derived SHAKAPACKER_DEV_SERVER_PORT" do
        described_class.start(:development)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("5001")
      end

      it "does not set RENDERER_PORT for OSS users without a renderer" do
        described_class.start(:development)
        expect(ENV).not_to have_key("RENDERER_PORT")
      end

      it "does not set REACT_RENDERER_URL for OSS users without a renderer" do
        described_class.start(:development)
        expect(ENV).not_to have_key("REACT_RENDERER_URL")
      end

      it "still applies RENDERER_PORT when the user has pre-set a renderer env var" do
        # A user without the Pro gem who is configuring their own node renderer
        # is signaled by any RENDERER_* env var. The guard should treat them
        # the same as a Pro user and apply the derived block.
        ENV["RENDERER_PORT"] = "3800"
        described_class.start(:development)
        expect(ENV.fetch("RENDERER_PORT", nil)).to eq("5002")
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:5002")
      end
    end

    context "when PORT/SHAKAPACKER_DEV_SERVER_PORT are set to empty strings" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      it "treats PORT='' as unset and applies the selected Rails port" do
        ENV["PORT"] = ""
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      it "treats SHAKAPACKER_DEV_SERVER_PORT='' as unset and applies the selected webpack port" do
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = ""
        described_class.start(:development)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("3035")
      end
    end

    context "when PORT/SHAKAPACKER_DEV_SERVER_PORT hold invalid values" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      it "overwrites an out-of-range PORT with the selected Rails port" do
        ENV["PORT"] = "99999"
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      it "overwrites a non-numeric PORT with the selected Rails port" do
        ENV["PORT"] = "abc"
        described_class.start(:development)
        expect(ENV.fetch("PORT", nil)).to eq("3000")
      end

      it "overwrites an out-of-range SHAKAPACKER_DEV_SERVER_PORT" do
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "99999"
        described_class.start(:development)
        expect(ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)).to eq("3035")
      end
    end

    context "when REACT_RENDERER_URL is set without RENDERER_PORT" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      it "warns that the node renderer may bind to a different port" do
        ENV["REACT_RENDERER_URL"] = "http://localhost:3801"
        expect { described_class.start(:development) }
          .to output(/set without RENDERER_PORT/).to_stderr
      end

      it "does not warn for a remote renderer URL when no local renderer process is being configured" do
        ENV["REACT_RENDERER_URL"] = "http://renderer:3801"
        expect { described_class.start(:development) }
          .not_to output(/set without RENDERER_PORT/).to_stderr
      end
    end

    context "when legacy RENDERER_URL is set without REACT_RENDERER_URL" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      it "warns about the rename so silent fallback to the default URL is surfaced" do
        ENV["RENDERER_URL"] = "http://renderer:3800"
        expect { described_class.start(:development) }
          .to output(/RENDERER_URL is set but REACT_RENDERER_URL is not/).to_stderr
      end

      it "does not warn when both are set to the same value" do
        ENV["RENDERER_URL"] = "http://renderer:3800"
        ENV["REACT_RENDERER_URL"] = "http://renderer:3800"
        expect { described_class.start(:development) }
          .not_to output(/RENDERER_URL/).to_stderr
      end

      it "warns when both are set but the values disagree" do
        ENV["RENDERER_URL"] = "http://renderer:3800"
        ENV["REACT_RENDERER_URL"] = "http://renderer:3801"
        expect { described_class.start(:development) }
          .to output(/both set but disagree/).to_stderr
      end

      it "tolerates whitespace-only differences as equivalent" do
        ENV["RENDERER_URL"] = "  http://renderer:3800  "
        ENV["REACT_RENDERER_URL"] = "http://renderer:3800"
        expect { described_class.start(:development) }
          .not_to output(/RENDERER_URL/).to_stderr
      end
    end

    context "when RENDERER_PORT is set explicitly without a base port" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      it "derives REACT_RENDERER_URL from the explicit RENDERER_PORT" do
        ENV["RENDERER_PORT"] = "3801"
        described_class.start(:development)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:3801")
      end

      it "announces the derived REACT_RENDERER_URL on stderr alongside other env-mutation warnings" do
        ENV["RENDERER_PORT"] = "3801"
        expect { described_class.start(:development) }
          .to output(%r{RENDERER_PORT=3801 set without REACT_RENDERER_URL; deriving REACT_RENDERER_URL=http://localhost:3801}).to_stderr
      end

      it "leaves a pre-existing REACT_RENDERER_URL untouched" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://renderer.internal:3801"
        described_class.start(:development)
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://renderer.internal:3801")
      end

      it "warns when RENDERER_PORT and REACT_RENDERER_URL disagree" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://localhost:3800"
        expect { described_class.start(:development) }
          .to output(%r{RENDERER_PORT=3801 does not match REACT_RENDERER_URL=http://localhost:3800}).to_stderr
      end

      it "does not warn when RENDERER_PORT appears inside REACT_RENDERER_URL" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://renderer.internal:3801"
        expect { described_class.start(:development) }.not_to output(/does not match/).to_stderr
      end

      # Basic-auth password digits used to trick the pre-URI.parse guard regex:
      # `[^/]+` would backtrack, match `user` as host, and consume `:3800` from
      # the password. The early `return true` was skipped, URI.parse returned
      # the scheme default (80), and the mismatch check fired spuriously.
      it "does not warn for a basic-auth URL where the password contains digits matching RENDERER_PORT" do
        ENV["RENDERER_PORT"] = "3800"
        ENV["REACT_RENDERER_URL"] = "http://user:3800@renderer.internal:3800"
        expect { described_class.start(:development) }.not_to output(/does not match/).to_stderr
      end

      it "warns when a short RENDERER_PORT is only a substring of the URL port" do
        # :80 is a substring of :3800 — substring matching would miss this mismatch.
        ENV["RENDERER_PORT"] = "80"
        ENV["REACT_RENDERER_URL"] = "http://localhost:3800"
        expect { described_class.start(:development) }
          .to output(/RENDERER_PORT=80 does not match/).to_stderr
      end

      it "warns, deletes the bad RENDERER_PORT, and skips URL construction when RENDERER_PORT is non-numeric" do
        ENV["RENDERER_PORT"] = "abc"
        expect { described_class.start(:development) }
          .to output(/RENDERER_PORT=.*not a valid port \(1\.\.65535\)/).to_stderr
        expect(ENV.fetch("RENDERER_PORT", nil)).to be_nil
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to be_nil
      end

      it "clears a localhost REACT_RENDERER_URL when invalid RENDERER_PORT would otherwise " \
         "leave Rails on a stale port" do
        ENV["RENDERER_PORT"] = "abc"
        ENV["REACT_RENDERER_URL"] = "http://localhost:3900"
        expect { described_class.start(:development) }
          .to output(%r{Clearing REACT_RENDERER_URL=http://localhost:3900}).to_stderr
        expect(ENV.fetch("RENDERER_PORT", nil)).to be_nil
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to be_nil
      end

      it "keeps a remote REACT_RENDERER_URL when invalid RENDERER_PORT is ignored" do
        ENV["RENDERER_PORT"] = "abc"
        ENV["REACT_RENDERER_URL"] = "http://renderer.internal:3900"
        described_class.start(:development)
        expect(ENV.fetch("RENDERER_PORT", nil)).to be_nil
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://renderer.internal:3900")
      end

      it "deletes an out-of-range RENDERER_PORT so the Procfile fallback can apply" do
        ENV["RENDERER_PORT"] = "99999"
        described_class.start(:development)
        expect(ENV.fetch("RENDERER_PORT", nil)).to be_nil
      end

      it "warns and skips URL construction when RENDERER_PORT is out of range" do
        ENV["RENDERER_PORT"] = "0"
        expect { described_class.start(:development) }
          .to output(/RENDERER_PORT=.*not a valid port/).to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to be_nil
      end

      it "accepts RENDERER_PORT with surrounding whitespace and writes the stripped value back to ENV" do
        ENV["RENDERER_PORT"] = "  3801  "
        described_class.start(:development)
        # Derived URL uses the stripped value, not the raw whitespace-padded env.
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:3801")
        # ENV is also normalized so the Procfile's ${RENDERER_PORT:-3800} expansion
        # propagates the clean value to the node renderer subprocess.
        expect(ENV.fetch("RENDERER_PORT", nil)).to eq("3801")
      end

      # URI preserves host case, so `URI.parse("http://LOCALHOST:3900").hostname`
      # returns "LOCALHOST". Without downcasing in `localhost_renderer_url?`, the
      # invalid-port remediation path would treat the URL as remote and skip
      # clearing it, leaving Rails targeting the stale port while node falls
      # back to 3800.
      it "clears an uppercase localhost REACT_RENDERER_URL when RENDERER_PORT is invalid" do
        ENV["RENDERER_PORT"] = "abc"
        ENV["REACT_RENDERER_URL"] = "http://LOCALHOST:3900"
        expect { described_class.start(:development) }
          .to output(%r{Clearing REACT_RENDERER_URL=http://LOCALHOST:3900}).to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to be_nil
      end

      # Sibling helpers in this file use `.strip.empty?` for the same env var;
      # without that here, a whitespace-only REACT_RENDERER_URL would bypass
      # the empty check and trigger a confusing mismatch warning instead of
      # auto-deriving the URL from RENDERER_PORT.
      it "treats a whitespace-only REACT_RENDERER_URL as empty and derives from RENDERER_PORT" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "   "
        expect { described_class.start(:development) }
          .to output(%r{deriving REACT_RENDERER_URL=http://localhost:3801}).to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to eq("http://localhost:3801")
      end
    end

    context "with IPv6 localhost REACT_RENDERER_URL" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      # URI.parse("http://[::1]:3800").host returns "[::1]" (with brackets),
      # while .hostname returns "::1" (bracket-stripped). Using .host here
      # would make IPv6 localhost URLs silently bypass the localhost-only
      # advisory paths.
      it "warns for an IPv6 localhost URL set without RENDERER_PORT" do
        ENV["REACT_RENDERER_URL"] = "http://[::1]:3801"
        expect { described_class.start(:development) }
          .to output(/set without RENDERER_PORT/).to_stderr
      end

      it "clears an IPv6 localhost URL when RENDERER_PORT is invalid" do
        ENV["RENDERER_PORT"] = "abc"
        ENV["REACT_RENDERER_URL"] = "http://[::1]:3900"
        expect { described_class.start(:development) }
          .to output(%r{Clearing REACT_RENDERER_URL=http://\[::1\]:3900}).to_stderr
        expect(ENV.fetch("REACT_RENDERER_URL", nil)).to be_nil
      end

      # The pre-URI.parse regex used `[^@/:]+` for the host, which stops at the
      # `[` of `[::1]` so `:\d+` never anchors on the real port — the function
      # returned `true` (mismatch) even when RENDERER_PORT agreed with the URL.
      it "does not warn when RENDERER_PORT agrees with an IPv6 REACT_RENDERER_URL" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://[::1]:3801"
        expect { described_class.start(:development) }.not_to output(/does not match/).to_stderr
      end

      it "warns when RENDERER_PORT disagrees with an IPv6 REACT_RENDERER_URL" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://[::1]:3800"
        expect { described_class.start(:development) }
          .to output(%r{RENDERER_PORT=3801 does not match REACT_RENDERER_URL=http://\[::1\]:3800}).to_stderr
      end
    end

    context "when REACT_RENDERER_URL has no explicit port" do
      include_context "with clean port env"

      before do
        mock_system_calls
        allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
          .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
      end

      # URI.parse("http://localhost").port returns the scheme default (80),
      # which would silently "match" RENDERER_PORT=80 without this check.
      it "warns about the mismatch when RENDERER_PORT is set and the URL omits a port" do
        ENV["RENDERER_PORT"] = "3801"
        ENV["REACT_RENDERER_URL"] = "http://localhost"
        expect { described_class.start(:development) }
          .to output(%r{RENDERER_PORT=3801 does not match REACT_RENDERER_URL=http://localhost}).to_stderr
      end

      it "still flags the mismatch when RENDERER_PORT matches the scheme default" do
        ENV["RENDERER_PORT"] = "80"
        ENV["REACT_RENDERER_URL"] = "http://localhost"
        expect { described_class.start(:development) }
          .to output(%r{RENDERER_PORT=80 does not match REACT_RENDERER_URL=http://localhost}).to_stderr
      end
    end
  end

  describe "invalid PORT / SHAKAPACKER_DEV_SERVER_PORT warnings" do
    include_context "with clean port env"

    before do
      allow(ReactOnRails::Dev::PackGenerator).to receive(:generate).with(any_args)
      allow_any_instance_of(Kernel).to receive(:system).and_return(true)
      allow_any_instance_of(Kernel).to receive(:exit)
      allow(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile)
      allow(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager)
      allow(ReactOnRails::Dev::DatabaseChecker).to receive(:check_database).and_return(true)
      allow(ReactOnRails::Dev::PortSelector).to receive(:select_ports!)
        .and_return({ rails: 3000, webpack: 3035, renderer: nil, base_port_mode: false })
    end

    it "warns when overwriting a non-numeric PORT" do
      ENV["PORT"] = "abc"
      expect { described_class.start(:development) }
        .to output(/PORT=.*"abc".*not a valid port; using 3000/).to_stderr
    end

    it "warns when overwriting a non-numeric SHAKAPACKER_DEV_SERVER_PORT" do
      ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "xyz"
      expect { described_class.start(:development) }
        .to output(/SHAKAPACKER_DEV_SERVER_PORT=.*"xyz".*not a valid port; using 3035/).to_stderr
    end

    it "does not warn when PORT is unset" do
      expect { described_class.start(:development) }
        .not_to output(/PORT=.*not a valid port/).to_stderr
    end
  end

  describe "browser auto-open readiness" do
    it "normalizes routes to request paths" do
      expect(described_class.send(:build_request_path, nil)).to eq("/")
      expect(described_class.send(:build_request_path, "/")).to eq("/")
      expect(described_class.send(:build_request_path, "hello_world")).to eq("/hello_world")
      expect(described_class.send(:build_request_path, "/hello_server")).to eq("/hello_server")
    end

    it "treats a successful response as ready" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(described_class).to receive(:http_get_localhost).with(3000, "/").and_return(response)

      expect(described_class.send(:app_route_ready?, 3000, "/")).to be true
    end

    it "treats a redirect response as ready" do
      response = Net::HTTPFound.new("1.1", "302", "Found")
      allow(described_class).to receive(:http_get_localhost).with(3000, "/").and_return(response)

      expect(described_class.send(:app_route_ready?, 3000, "/")).to be true
    end

    it "does not treat a server error response as ready" do
      response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      allow(described_class).to receive(:http_get_localhost).with(3000, "/").and_return(response)

      expect(described_class.send(:app_route_ready?, 3000, "/")).to be false
    end

    it "waits for the route to respond successfully before opening the browser" do
      allow(described_class).to receive(:browser_auto_open_allowed?).and_return(true)
      allow(Thread).to receive(:new).and_yield
      allow(described_class).to receive(:wait_for_app_route).with(3000, "/").and_return(true)
      allow(described_class).to receive(:prepare_browser_open_once_marker).with(true).and_return(:claimed)
      expect(described_class).to receive(:open_browser).with("http://localhost:3000").and_return(true)

      described_class.send(:schedule_browser_open, 3000, route: "/", once: true)
    end
  end

  describe ".browser_auto_open_allowed?" do
    around do |example|
      original_ci = ENV.fetch("CI", nil)
      example.run
    ensure
      original_ci.nil? ? ENV.delete("CI") : ENV["CI"] = original_ci
    end

    it "returns true when explicit is true, even in CI" do
      ENV["CI"] = "1"
      expect(described_class.send(:browser_auto_open_allowed?, explicit: true)).to be true
    end

    it "returns false in CI when explicit is false" do
      ENV["CI"] = "1"
      expect(described_class.send(:browser_auto_open_allowed?, explicit: false)).to be false
    end
  end

  describe "WSL detection" do
    saved = {}

    around do |example|
      saved = {}
      saved = ENV.to_h.slice("WSL_DISTRO_NAME", "WSLENV")
      ENV.delete("WSL_DISTRO_NAME")
      ENV.delete("WSLENV")
      example.run
    ensure
      saved.each { |k, v| ENV[k] = v }
      (%w[WSL_DISTRO_NAME WSLENV] - saved.keys).each { |k| ENV.delete(k) }
    end

    it "detects WSL when WSL_DISTRO_NAME is set" do
      ENV["WSL_DISTRO_NAME"] = "Ubuntu"
      expect(described_class.send(:wsl?)).to be true
    end

    it "detects WSL when WSLENV is set" do
      ENV["WSLENV"] = "USERPROFILE"
      expect(described_class.send(:wsl?)).to be true
    end

    it "returns false when neither WSL variable is set" do
      expect(described_class.send(:wsl?)).to be false
    end

    it "returns wslview on WSL when available" do
      ENV["WSL_DISTRO_NAME"] = "Ubuntu"
      allow(described_class).to receive(:command_available?).and_return(false)
      allow(described_class).to receive(:command_available?).with("wslview").and_return(true)

      expect(described_class.send(:linux_browser_command)).to eq(["wslview"])
    end

    it "falls back to wsl-open on WSL when wslview is unavailable" do
      ENV["WSL_DISTRO_NAME"] = "Ubuntu"
      allow(described_class).to receive(:command_available?).and_return(false)
      allow(described_class).to receive(:command_available?).with("wsl-open").and_return(true)

      expect(described_class.send(:linux_browser_command)).to eq(["wsl-open"])
    end

    it "falls back to xdg-open on WSL when neither WSL launcher is available" do
      ENV["WSL_DISTRO_NAME"] = "Ubuntu"
      allow(described_class).to receive(:command_available?).and_return(false)
      allow(described_class).to receive(:command_available?).with("xdg-open").and_return(true)

      expect(described_class.send(:linux_browser_command)).to eq(["xdg-open"])
    end

    it "returns nil on WSL when no launcher is available" do
      ENV["WSL_DISTRO_NAME"] = "Ubuntu"
      allow(described_class).to receive(:command_available?).and_return(false)

      expect(described_class.send(:linux_browser_command)).to be_nil
    end

    it "returns xdg-open on non-WSL Linux" do
      allow(described_class).to receive(:command_available?).and_return(false)
      allow(described_class).to receive(:command_available?).with("xdg-open").and_return(true)

      expect(described_class.send(:linux_browser_command)).to eq(["xdg-open"])
    end
  end

  describe ".kill_processes" do
    include_context "with clean port env"

    before do
      allow_any_instance_of(Kernel).to receive(:`).and_return("")
      allow(File).to receive(:exist?).and_return(false)
    end

    it "attempts to kill development processes" do
      # Mock Open3.capture2 calls that find_process_pids uses
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "rails", err: File::NULL).and_return(["1234\n5678", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "node.*react[-_]on[-_]rails", err: File::NULL)
        .and_return(["2345", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "overmind", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "foreman", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "ruby.*puma", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "webpack-dev-server", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "bin/shakapacker-dev-server", err: File::NULL).and_return(["", nil])

      # Mock lsof calls for port checking
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])

      allow(Process).to receive(:pid).and_return(9999) # Current process PID
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)
      expect(Process).to receive(:kill).with("TERM", 2345)

      described_class.kill_processes
    end

    it "kills processes on ports 3000 and 3001" do
      # No pattern-based processes
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      # Mock port processes
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["3456", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["3457\n3458", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3456)
      expect(Process).to receive(:kill).with("TERM", 3457)
      expect(Process).to receive(:kill).with("TERM", 3458)

      described_class.kill_processes
    end

    it "cleans up socket files when they exist" do
      # Make sure no processes are found so cleanup_socket_files gets called
      allow(Open3).to receive(:capture2).and_return(["", nil])

      allow(Dir).to receive(:glob).with("tmp/sockets/overmind*.sock").and_return([])
      allow(File).to receive(:exist?).with(".overmind.sock").and_return(true)
      allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)
      expect(File).to receive(:delete).with(".overmind.sock")

      described_class.kill_processes
    end

    it "cleans up renamed/copied overmind sockets via the same glob FileManager uses" do
      # Mirrors FileManager#cleanup_overmind_sockets: variants like
      # overmind-4100.sock from copied app dirs must also be removed during
      # `bin/dev kill`, not just at startup.
      allow(Open3).to receive(:capture2).and_return(["", nil])

      copied = "tmp/sockets/overmind-4100.sock"
      allow(Dir).to receive(:glob).with("tmp/sockets/overmind*.sock").and_return([copied])
      allow(File).to receive(:exist?).with(".overmind.sock").and_return(false)
      allow(File).to receive(:exist?).with(copied).and_return(true)
      allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)
      expect(File).to receive(:delete).with(copied)

      described_class.kill_processes
    end

    # Regression: previously kill_processes used `||` which short-circuited
    # subsequent cleanup steps as soon as one returned truthy. A successful
    # pattern-based kill would leave stale port-bound processes and socket/pid
    # files behind. All three cleanup helpers must always run.
    it "runs port kills and socket cleanup even when pattern-based kill found processes" do
      # The catch-all must be defined FIRST. RSpec uses the most-recently-defined
      # matching stub regardless of specificity (`any_args` does not yield to a
      # narrower matcher automatically), so the specific "rails" stub below wins
      # because it is defined last. Reversing the order would cause
      # `kill_running_processes` to always return false, missing the regression
      # path this test covers (the old `||` short-circuit would have skipped the
      # remaining cleanup steps once pattern-based kill returned truthy).
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "rails", err: File::NULL).and_return(["1234", nil])
      allow(Process).to receive(:pid).and_return(9999)
      allow(Process).to receive(:kill)

      expect(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      expect(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])

      socket = ".overmind.sock"
      allow(Dir).to receive(:glob).with("tmp/sockets/overmind*.sock").and_return([])
      allow(File).to receive(:exist?).with(socket).and_return(true)
      allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)
      expect(File).to receive(:delete).with(socket)

      described_class.kill_processes
    end

    it "targets base-port-derived ports when REACT_ON_RAILS_BASE_PORT is active" do
      # Without base-port awareness, `bin/dev kill` in a worktree running on
      # 5000/5001/5002 would fall back to killing stale processes on 3000/3001
      # instead — the actual ports would be left untouched. RENDERER_PORT is
      # set so `pro_renderer_active?` returns true via `renderer_env_signal?`
      # (the Pro gem isn't loaded in the open-source spec suite), exercising
      # the base+2 inclusion path.
      ENV["RENDERER_PORT"] = "5002"
      allow(ReactOnRails::Dev::PortSelector)
        .to receive(:base_port_hash)
        .and_return({ rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true })
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5000", err: File::NULL).and_return(["4501", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5001", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5002", err: File::NULL).and_return(["", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 4501)

      described_class.kill_processes
    end

    it "skips the base-port-derived renderer port when Pro renderer support is inactive" do
      allow(ReactOnRails::Dev::PortSelector)
        .to receive(:base_port_hash)
        .and_return({ rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true })
      allow(described_class).to receive(:pro_renderer_active?).and_return(false)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":5002", err: File::NULL)

      described_class.kill_processes
    end

    it "includes the base-port-derived renderer port when Pro gem is loaded even without renderer env vars" do
      # bin/dev kill is usually invoked from a fresh shell where RENDERER_PORT
      # and REACT_RENDERER_URL aren't carried over. The Pro renderer runs as
      # `node renderer/node-renderer.js` (see react_on_rails_pro Procfile.dev),
      # which the development_processes pattern (`node.*react[-_]on[-_]rails`)
      # does not match — so port-based killing is the only reliable path to
      # reap a stale renderer on base+2. In base-port mode the user owns the
      # port range, so the conservative env-var gate isn't needed.
      allow(ReactOnRails::Dev::PortSelector)
        .to receive(:base_port_hash)
        .and_return({ rails: 5000, webpack: 5001, renderer: 5002, base_port_mode: true })
      allow(described_class).to receive(:pro_renderer_active?).and_return(true)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":5001", err: File::NULL).and_return(["", nil])
      expect(Open3).to receive(:capture2).with("lsof", "-ti", ":5002", err: File::NULL).and_return(["", nil])

      described_class.kill_processes
    end

    it "does not widen kill scope to 3800 when the Pro gem is loaded but no renderer env vars are set" do
      # Pro gem may be present in OSS+Pro-gem apps that never run the
      # renderer. Without an explicit RENDERER_PORT / REACT_RENDERER_URL /
      # RENDERER_URL signal, `bin/dev kill` must not target 3800 — that
      # port could belong to an unrelated process.
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      allow(described_class).to receive(:pro_renderer_active?).and_return(true)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL)

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).not_to receive(:kill).with("TERM", 3801)

      described_class.kill_processes
    end

    it "targets 3800 when a localhost REACT_RENDERER_URL is set without an explicit :port" do
      ENV["REACT_RENDERER_URL"] = "http://localhost"
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      allow(described_class).to receive(:pro_renderer_active?).and_return(true)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL).and_return(["3801", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3801)

      described_class.kill_processes
    end

    it "targets the configured renderer port when Pro renderer support is active without a base port" do
      ENV["RENDERER_PORT"] = "3900"
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      allow(described_class).to receive(:pro_renderer_active?).and_return(true)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL)
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3900", err: File::NULL).and_return(["3901", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3901)

      described_class.kill_processes
    end

    it "does not target the default renderer port for a remote renderer URL" do
      ENV["REACT_RENDERER_URL"] = "https://renderer.internal:3800"
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL)

      described_class.kill_processes
    end

    it "targets the local renderer URL port when RENDERER_PORT is not set" do
      ENV["REACT_RENDERER_URL"] = "http://localhost:3900"
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL)
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3900", err: File::NULL).and_return(["3901", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3901)

      described_class.kill_processes
    end

    it "does not treat userinfo digits as an explicit local renderer URL port" do
      ENV["REACT_RENDERER_URL"] = "http://user:3800@localhost"
      allow(ReactOnRails::Dev::PortSelector).to receive(:base_port_hash).and_return(nil)
      allow(described_class).to receive(:pro_renderer_active?).and_return(true)
      # No pattern-based processes so kill_port_processes runs.
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])
      expect(Open3).not_to receive(:capture2).with("lsof", "-ti", ":80", err: File::NULL)
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3800", err: File::NULL).and_return(["3801", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3801)

      described_class.kill_processes
    end
  end

  describe ".find_port_pids" do
    it "finds PIDs listening on a specific port" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234\n5678", nil])
      allow(Process).to receive(:pid).and_return(9999)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([1234, 5678])
    end

    it "excludes current process PID" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234\n9999", nil])
      allow(Process).to receive(:pid).and_return(9999)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([1234])
    end

    it "returns empty array when lsof is not found" do
      allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([])
    end

    it "returns empty array on permission denied" do
      allow(Open3).to receive(:capture2).and_raise(Errno::EACCES)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([])
    end
  end

  describe ".clean_generated_assets_and_caches" do
    around do |example|
      original_renderer_cache_path = ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH", nil)
      Dir.mktmpdir("react-on-rails-clean") do |tmpdir|
        Dir.mktmpdir("react-on-rails-clean-outside") do |outside_tmpdir|
          @clean_test_outside_root = outside_tmpdir
          Dir.chdir(tmpdir) do
            example.run
          end
        end
      end
    ensure
      @clean_test_outside_root = nil
      if original_renderer_cache_path.nil?
        ENV.delete("RENDERER_SERVER_BUNDLE_CACHE_PATH")
      else
        ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = original_renderer_cache_path
      end
    end

    before do
      allow(Rails).to receive(:root).and_return(Pathname.new(Dir.pwd))
      allow(described_class).to receive(:kill_processes)
    end

    def write_clean_test_shakapacker_config(content)
      FileUtils.mkdir_p("config")
      File.write("config/shakapacker.yml", content)
    end

    def create_clean_test_dirs(*paths)
      paths.each { |path| FileUtils.mkdir_p(path) }
    end

    def clean_test_outside_path(*parts)
      File.join(@clean_test_outside_root, *parts)
    end

    it "removes bundle outputs and cache paths derived from shakapacker.yml" do
      ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = "tmp/custom-renderer-cache"
      write_clean_test_shakapacker_config(<<~YAML)
        default:
          public_root_path: public
          public_output_path: packs
          private_output_path: ssr-generated
          cache_path: tmp/shakapacker

        development:
          public_output_path: webpack/development

        test:
          public_output_path: webpack/test
          cache_path: tmp/shakapacker-test

        production:
          public_output_path: webpack/production

        staging:
          public_output_path: webpack/staging
      YAML
      create_clean_test_dirs(
        "public/packs",
        "public/webpack/development",
        "public/webpack/test",
        "public/webpack/production",
        "public/webpack/staging",
        "ssr-generated",
        "tmp/shakapacker",
        "tmp/shakapacker-test",
        "tmp/cache",
        "node_modules/.cache",
        ".node-renderer-bundles",
        "tmp/custom-renderer-cache",
        "tmp/node-renderer-bundles-test-0"
      )

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(described_class).to have_received(:kill_processes)
        expect(output).to include("config/shakapacker.yml")
        expect(output).to include("public/webpack/development")
        expect(output).to include("public/webpack/staging")
        expect(output).to include("tmp/shakapacker-test")
        expect(File).not_to exist("public/packs")
        expect(File).not_to exist("public/webpack/development")
        expect(File).not_to exist("public/webpack/test")
        expect(File).not_to exist("public/webpack/production")
        expect(File).not_to exist("public/webpack/staging")
        expect(File).not_to exist("ssr-generated")
        expect(File).not_to exist("tmp/shakapacker")
        expect(File).not_to exist("tmp/shakapacker-test")
        expect(File).not_to exist("tmp/cache")
        expect(File).not_to exist("node_modules/.cache")
        expect(File).not_to exist(".node-renderer-bundles")
        expect(File).not_to exist("tmp/custom-renderer-cache")
        expect(File).not_to exist("tmp/node-renderer-bundles-test-0")
      end
    end

    it "reports missing shakapacker.yml and still removes common caches" do
      create_clean_test_dirs(
        "tmp/cache",
        "node_modules/.cache",
        ".node-renderer-bundles"
      )

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(output).to include("Shakapacker config not found: config/shakapacker.yml")
        expect(output).to include("Skipping configured Shakapacker output/cache paths")
        expect(output).not_to include("Reading Shakapacker config")
        expect(File).not_to exist("tmp/cache")
        expect(File).not_to exist("node_modules/.cache")
        expect(File).not_to exist(".node-renderer-bundles")
      end
    end

    it "removes broken symlink cleanup targets when the link target stays inside the app root" do
      write_clean_test_shakapacker_config(<<~YAML)
        default:
          public_root_path: public
          public_output_path: broken-packs
      YAML
      FileUtils.mkdir_p("public")
      File.symlink(File.expand_path("tmp/deleted-packs", Dir.pwd), "public/broken-packs")

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(output).to include("Removed public/broken-packs")
        expect(File).not_to be_symlink("public/broken-packs")
      end
    end

    it "skips cleanup targets when realpath is blocked by permissions" do
      write_clean_test_shakapacker_config(<<~YAML)
        default:
          public_root_path: public
          public_output_path: restricted-packs
      YAML
      create_clean_test_dirs("public/restricted-packs")
      restricted_path = File.expand_path("public/restricted-packs", Dir.pwd)
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with(restricted_path).and_raise(Errno::EACCES)

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(output).to include("Skipping unsafe cleanup path: public/restricted-packs")
        expect(File).to exist("public/restricted-packs")
      end
    end

    it "warns when a cleanup target remains after removal" do
      write_clean_test_shakapacker_config(<<~YAML)
        default:
          public_root_path: public
          public_output_path: partial-packs
      YAML
      create_clean_test_dirs("public/partial-packs")
      partial_path = File.expand_path("public/partial-packs", Dir.pwd)
      allow(FileUtils).to receive(:rm_rf).and_call_original
      allow(FileUtils).to receive(:rm_rf).with(partial_path)

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(output).to include("Partially removed public/partial-packs")
        expect(File).to exist("public/partial-packs")
      end
    end

    it "skips shakapacker.yml paths that resolve outside the app root or to broad root directories" do
      outside_packs = clean_test_outside_path("outside-packs")
      outside_cache = clean_test_outside_path("outside-cache")
      outside_webpack = clean_test_outside_path("outside-webpack")
      outside_renderer_cache = clean_test_outside_path("outside-renderer-cache")
      ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] = outside_renderer_cache
      FileUtils.mkdir_p(outside_packs)
      FileUtils.mkdir_p(File.join(outside_webpack, "development"))
      FileUtils.mkdir_p(outside_renderer_cache)
      FileUtils.mkdir_p("public")
      File.write(File.join(outside_packs, "keep.txt"), "keep")
      File.write(File.join(outside_webpack, "development", "keep.txt"), "keep")
      File.write(File.join(outside_renderer_cache, "keep.txt"), "keep")
      File.symlink(outside_webpack, "public/webpack")
      write_clean_test_shakapacker_config(<<~YAML)
        default:
          public_root_path: #{@clean_test_outside_root}
          public_output_path: outside-packs
          cache_path: #{outside_cache}

        test:
          public_root_path: public
          public_output_path: .
          cache_path: tmp

        development:
          public_root_path: public
          public_output_path: webpack/development
      YAML

      output = capture_stdout { described_class.clean_generated_assets_and_caches }

      aggregate_failures do
        expect(File).to exist(File.join(outside_packs, "keep.txt"))
        expect(File).to exist(File.join(outside_webpack, "development", "keep.txt"))
        expect(File).to exist(File.join(outside_renderer_cache, "keep.txt"))
        expect(File).to exist("public")
        expect(output).to include("Skipping unsafe cleanup path")
      end
    end
  end

  describe ".kill_port_processes" do
    it "kills processes on specified ports" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["5678", nil])
      allow(Process).to receive(:pid).and_return(9999)

      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)

      result = described_class.kill_port_processes([3000, 3001])
      expect(result).to be true
    end

    it "returns false when no processes found on ports" do
      allow(Open3).to receive(:capture2).and_return(["", nil])

      result = described_class.kill_port_processes([3000, 3001])
      expect(result).to be false
    end
  end

  describe ".terminate_processes" do
    it "successfully kills processes" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)

      described_class.terminate_processes(pids)
    end

    it "handles ESRCH (process not found) silently" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(Errno::ESRCH)

      # Should not raise an error and should not output anything
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles EPERM (permission denied) with warning" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(Errno::EPERM)

      # Should not raise an error but should output a warning
      expect { described_class.terminate_processes(pids) }.to output(/permission denied/).to_stdout_from_any_process
    end

    it "handles mixed success and ESRCH" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      allow(Process).to receive(:kill).with("TERM", 5678).and_raise(Errno::ESRCH)

      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles mixed success and EPERM" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      allow(Process).to receive(:kill).with("TERM", 5678).and_raise(Errno::EPERM)

      expect do
        described_class.terminate_processes(pids)
      end.to output(/5678.*permission denied/).to_stdout_from_any_process
    end

    it "handles ArgumentError (invalid signal)" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(ArgumentError)

      # Should not raise an error
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles RangeError (invalid PID)" do
      pids = [999_999_999_999]
      allow(Process).to receive(:kill).with("TERM", 999_999_999_999).and_raise(RangeError)

      # Should not raise an error
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end
  end

  describe ".procfile_port" do
    around do |example|
      old_port = ENV.fetch("PORT", nil)
      ENV.delete("PORT")
      example.run
    ensure
      ENV["PORT"] = old_port
    end

    it "returns 3000 for Procfile.dev when PORT is unset" do
      expect(described_class.send(:procfile_port, "Procfile.dev")).to eq(3000)
    end

    it "returns 3001 for Procfile.dev-prod-assets when PORT is unset" do
      expect(described_class.send(:procfile_port, "Procfile.dev-prod-assets")).to eq(3001)
    end

    it "returns the auto-detected port for Procfile.dev when PORT is set" do
      ENV["PORT"] = "3001"
      expect(described_class.send(:procfile_port, "Procfile.dev")).to eq(3001)
    end

    it "returns the PORT value for Procfile.dev-prod-assets when PORT is set" do
      ENV["PORT"] = "4000"
      expect(described_class.send(:procfile_port, "Procfile.dev-prod-assets")).to eq(4000)
    end
  end

  describe ".show_help" do
    it "displays help information" do
      output = capture_stdout { described_class.show_help }

      expect(output).to match(%r{Usage: bin/dev \[command\]})
    end

    it "preserves webpack-specific mode descriptions for webpack apps" do
      allow(described_class).to receive(:configured_assets_bundler).and_return("webpack")

      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(/HMR development with webpack-dev-server/)
        expect(output).to match(/Webpack dev server for fast recompilation/)
        expect(output).to match(/Webpack watch mode for auto-recompilation/)
      end
    end

    it "uses neutral/rspack mode descriptions for rspack live-reload apps" do
      allow(described_class).to receive_messages(
        configured_assets_bundler: "rspack",
        default_dev_server_mode: :live_reload,
        development_dev_server_config: { "hmr" => false, "live_reload" => true }
      )

      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(/Live reload development with Rspack dev server/)
        expect(output).to match(/Full-page live reload enabled/)
        expect(output).to match(/Rspack dev server for fast recompilation/)
        expect(output).to match(%r{@rspack/plugin-react-refresh / ReactRefreshRspackPlugin})
        expect(output).to match(/Rspack watch mode for auto-recompilation/)
        expect(output).to match(/React Refresh requires HMR; current default mode is not HMR/)
        expect(output).to match(/HMR is disabled in your Shakapacker config/)
        expect(output).not_to match(/webpack-dev-server/)
        expect(output).not_to match(/Hot Module Replacement \(HMR\) enabled/)
        expect(output).not_to match(/Ensure you're running HMR mode/)
        expect(output).not_to match(/React Refresh only works in HMR mode/)
        expect(output).not_to match(/Webpack watch mode/)
        expect(output).not_to match(/Webpack compilation failed/)
      end
    end

    it "omits the bundler config-hint bullet on the webpack non-HMR path" do
      # Symmetric to the rspack live-reload case above: rspack_react_refresh_config_hint
      # returns "" for webpack, so the non-HMR troubleshooting block must not emit a
      # config/webpack/development.js bullet (that hint only belongs on the HMR path).
      allow(described_class).to receive_messages(
        configured_assets_bundler: "webpack",
        default_dev_server_mode: :live_reload,
        development_dev_server_config: { "hmr" => false, "live_reload" => true }
      )

      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(/React Refresh requires HMR; current default mode is not HMR/)
        expect(output).not_to match(%r{config/webpack/development.js})
        expect(output).not_to match(/ReactRefreshWebpackPlugin/)
      end
    end

    it "uses generic React Refresh guidance for future bundlers" do
      allow(described_class).to receive_messages(
        configured_assets_bundler: "future",
        development_dev_server_config: { "hmr" => true }
      )

      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(/Check your bundler's React Refresh plugin documentation/)
        expect(output).not_to match(%r{config/rspack/development.js})
      end
    end

    it "treats live_reload true without hmr as live reload" do
      allow(described_class).to receive_messages(
        configured_assets_bundler: "rspack",
        default_dev_server_mode: :live_reload,
        development_dev_server_config: { "live_reload" => true }
      )

      output = capture_stdout { described_class.show_help }

      expect(output).to match(/Live reload development with Rspack dev server/)
      expect(output).not_to match(/HMR development with Rspack dev server/)
    end

    it "documents test asset workflows" do
      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(/TEST ASSET WORKFLOWS/)
        expect(output).to match(%r{bin/dev test-watch})
        expect(output).to match(%r{bin/dev static})
      end
    end

    it "documents the clean command" do
      output = capture_stdout { described_class.show_help }

      expect(output).to match(%r{clean\s+Kill dev processes and remove generated bundles/caches})
    end

    it "links to the published documentation for dev server and testing guidance" do
      output = capture_stdout { described_class.show_help }

      aggregate_failures do
        expect(output).to match(%r{https://reactonrails.com/docs/building-features/dev-server-and-testing/})
        expect(output).to match(%r{https://reactonrails.com/docs/building-features/testing-configuration/})
        expect(output).to match(%r{https://reactonrails.com/docs/})
      end
    end

    context "when Shakapacker config uses live reload instead of HMR" do
      include_context "with clean port env"

      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      before do
        FileUtils.mkdir_p("config")
        File.write("config/shakapacker.yml", <<~YAML)
          development:
            dev_server:
              hmr: false
              live_reload: true
        YAML
      end

      it "labels the default command and mode details as live reload" do
        expected_output = satisfy do |output|
          output.match?(/\(none\)\s+Start development server with live reload \(default\)/) &&
            !output.match?(/HMR Development mode \(default\)|Hot Module Replacement \(HMR\) enabled/) &&
            !output.match?(%r{\(none\) / hmr\s+Start development server with live reload \(default\)}) &&
            !output.include?("ReactRefreshWebpackPlugin") &&
            output.include?("React Refresh requires HMR; current default mode is not HMR.")
        end

        expect { described_class.show_help }.to output(expected_output).to_stdout_from_any_process
      end

      it "detects the default dev-server mode once per help render" do
        expect(ReactOnRails::Dev::ServerMode)
          .to receive(:detect).once.with(File.expand_path("config/shakapacker.yml", Dir.pwd)).and_return(:live_reload)

        expect { described_class.show_help }
          .to output(/Live reload development mode \(default\)/).to_stdout_from_any_process
      end

      it "passes the resolved Shakapacker config path into ServerMode" do
        allow(described_class)
          .to receive(:shakapacker_config_path).and_return("/tmp/app/config/custom-shakapacker.yml")
        expect(ReactOnRails::Dev::ServerMode)
          .to receive(:detect).with("/tmp/app/config/custom-shakapacker.yml").and_return(:live_reload)

        expect { described_class.show_help }
          .to output(/Live reload development mode \(default\)/).to_stdout_from_any_process
      end
    end

    context "when Shakapacker config enables HMR explicitly" do
      include_context "with clean port env"

      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      before do
        FileUtils.mkdir_p("config")
        File.write("config/shakapacker.yml", <<~YAML)
          development:
            dev_server:
              hmr: true
        YAML
      end

      # Triangulates the config-driven :hmr path (detect_from_config returns :hmr) against the
      # baseline specs that exercise the :hmr fallback when no config file is present.
      it "labels the default command and mode details as HMR" do
        expected_output = satisfy do |output|
          output.match?(%r{\(none\) / hmr\s+Start development server with HMR \(default\)}) &&
            output.include?("HMR Development mode (default)") &&
            output.include?("Hot Module Replacement (HMR) enabled") &&
            output.include?("ReactRefreshWebpackPlugin") &&
            !output.include?("React Refresh requires HMR; current default mode is not HMR.")
        end

        expect { described_class.show_help }.to output(expected_output).to_stdout_from_any_process
      end
    end

    context "when Shakapacker config disables both HMR and live reload" do
      include_context "with clean port env"

      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      before do
        FileUtils.mkdir_p("config")
        File.write("config/shakapacker.yml", <<~YAML)
          development:
            dev_server:
              live_reload: false
        YAML
      end

      it "labels the default command and mode details as the development server" do
        expected_output = satisfy do |output|
          output.match?(/\(none\)\s+Start development server \(default\)/) &&
            output.include?("Development server mode (default)") &&
            !output.match?(/HMR Development mode \(default\)|Hot Module Replacement \(HMR\) enabled/) &&
            !output.include?("ReactRefreshWebpackPlugin") &&
            output.include?("React Refresh requires HMR; current default mode is not HMR.")
        end

        expect { described_class.show_help }.to output(expected_output).to_stdout_from_any_process
      end
    end

    context "when base-port mode is active" do
      include_context "with clean port env"

      before do
        ENV["REACT_ON_RAILS_BASE_PORT"] = "5000"
      end

      it "advertises the base-derived Rails port for HMR mode" do
        expect { described_class.show_help }
          .to output(%r{HMR Development.*Access at.*http://localhost:5000/<route>}m).to_stdout_from_any_process
      end

      it "advertises the base-derived Rails port for production-assets mode" do
        expect { described_class.show_help }
          .to output(%r{Production-assets.*Access at.*http://localhost:5000/<route>}m).to_stdout_from_any_process
      end
    end

    context "when base-port mode is not active" do
      include_context "with clean port env"

      it "advertises 3001 for production-assets mode" do
        expect { described_class.show_help }
          .to output(%r{Production-assets.*Access at.*http://localhost:3001/<route>}m).to_stdout_from_any_process
      end
    end
  end

  describe ".shakapacker_config_base_dir" do
    it "uses Rails.root when Rails is loaded" do
      rails_root = Pathname.new("/tmp/rails-root")
      allow(Rails).to receive(:root).and_return(rails_root)

      expect(described_class.send(:shakapacker_config_base_dir)).to eq(rails_root.to_s)
    end

    it "falls back to the current working directory when Rails is not loaded" do
      Dir.mktmpdir("react-on-rails-cwd") do |cwd|
        Dir.chdir(cwd) do
          hide_const("Rails")

          expect(described_class.send(:shakapacker_config_base_dir)).to eq(Dir.pwd)
        end
      end
    end
  end

  describe ".shakapacker_config_path" do
    let(:rails_root) { Pathname.new(Dir.mktmpdir("react-on-rails-root")) }

    around do |example|
      original_config_path = ENV.fetch("SHAKAPACKER_CONFIG", nil)
      original_cwd = Dir.pwd
      ENV.delete("SHAKAPACKER_CONFIG")
      example.run
    ensure
      ENV["SHAKAPACKER_CONFIG"] = original_config_path
      Dir.chdir(original_cwd)
      FileUtils.remove_entry(rails_root) if rails_root.exist?
    end

    before do
      allow(Rails).to receive(:root).and_return(rails_root)
    end

    it "defaults to config/shakapacker.yml under Rails.root" do
      expect(described_class.send(:shakapacker_config_path)).to eq(
        rails_root.join("config", "shakapacker.yml").to_s
      )
    end

    it "resolves a relative SHAKAPACKER_CONFIG path against Rails.root" do
      ENV["SHAKAPACKER_CONFIG"] = "config/custom-shakapacker.yml"

      Dir.mktmpdir("react-on-rails-cwd") do |unrelated_cwd|
        Dir.chdir(unrelated_cwd) do
          expect(described_class.send(:shakapacker_config_path)).to eq(
            rails_root.join("config", "custom-shakapacker.yml").to_s
          )
        end
      end
    end

    it "preserves an absolute SHAKAPACKER_CONFIG path" do
      config_path = "/tmp/custom-shakapacker.yml"
      ENV["SHAKAPACKER_CONFIG"] = config_path

      expect(described_class.send(:shakapacker_config_path)).to eq(config_path)
    end

    it "uses the current working directory for relative config when Rails is not loaded" do
      hide_const("Rails")
      ENV["SHAKAPACKER_CONFIG"] = "config/custom-shakapacker.yml"

      Dir.mktmpdir("react-on-rails-cwd") do |cwd|
        Dir.chdir(cwd) do
          expect(described_class.send(:shakapacker_config_path)).to eq(
            File.expand_path("config/custom-shakapacker.yml", Dir.pwd)
          )
        end
      end
    end
  end

  describe ".parsed_shakapacker_config" do
    it "returns nil for ERB syntax errors" do
      allow(described_class).to receive(:shakapacker_config_path).and_return("config/shakapacker.yml")
      allow(File).to receive(:exist?).with("config/shakapacker.yml").and_return(true)
      allow(File).to receive(:read).with("config/shakapacker.yml").and_return("<% raise SyntaxError, 'bad erb' %>")

      expect(described_class.send(:parsed_shakapacker_config)).to be_nil
    end
  end

  describe ".development_dev_server_config" do
    it "uses the development dev_server hash as a whole when development overrides it" do
      allow(described_class).to receive(:parsed_shakapacker_config).and_return(
        "default" => { "dev_server" => { "hmr" => true, "host" => "0.0.0.0" } },
        "development" => { "dev_server" => { "port" => 3035 } }
      )

      aggregate_failures do
        expect(described_class.send(:development_dev_server_config)).to eq("port" => 3035)
        expect(described_class.send(:development_hmr_enabled?)).to be(true)
      end
    end

    it "normalizes selected dev_server keys to strings" do
      allow(described_class).to receive(:parsed_shakapacker_config).and_return(
        "default" => { dev_server: { hmr: true } },
        "development" => { "dev_server" => { "hmr" => false } }
      )

      aggregate_failures do
        expect(described_class.send(:development_dev_server_config)).to include("hmr" => false)
        expect(described_class.send(:development_dev_server_config)).not_to have_key(:hmr)
        expect(described_class.send(:development_hmr_enabled?)).to be(false)
      end
    end

    it "treats hmr only mode as HMR" do
      allow(described_class).to receive(:parsed_shakapacker_config).and_return(
        "development" => { "dev_server" => { "hmr" => "only" } }
      )

      expect(described_class.send(:development_hmr_enabled?)).to be(true)
    end
  end

  describe ".run_test_watch" do
    before do
      allow(described_class).to receive(:puts)
    end

    it "uses full mode in auto mode when no watcher is running" do
      allow(described_class).to receive(:find_process_pids).and_return([])

      expect(described_class).to receive(:exec).with({ "RAILS_ENV" => "test" }, "bin/shakapacker", "--watch")

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses client-only mode in auto mode when watcher is already running" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(true)

      expect(described_class).to receive(:exec).with(
        { "RAILS_ENV" => "test", "CLIENT_BUNDLE_ONLY" => "true" },
        "bin/shakapacker",
        "--watch"
      )

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses client-only mode in auto mode when legacy =yes watcher is running" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(true)

      expect(described_class).to receive(:exec).with(
        { "RAILS_ENV" => "test", "CLIENT_BUNDLE_ONLY" => "true" },
        "bin/shakapacker",
        "--watch"
      )

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses full mode when only a server-bundle watcher is running but private paths differ" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(false)

      expect(described_class).to receive(:exec).with({ "RAILS_ENV" => "test" }, "bin/shakapacker", "--watch")

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses client-only mode when full watcher is running and private paths are shared" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker-dev-server")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(true)

      expect(described_class).to receive(:exec).with(
        { "RAILS_ENV" => "test", "CLIENT_BUNDLE_ONLY" => "true" },
        "bin/shakapacker",
        "--watch"
      )

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses full mode when full watcher is running but sharing is unclear" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker-dev-server")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(false)

      expect(described_class).to receive(:exec).with({ "RAILS_ENV" => "test" }, "bin/shakapacker", "--watch")

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "uses client-only mode when a dev-server/watcher pair is running" do
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=true bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch")
        .and_return([])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker-dev-server")
        .and_return([54_321])
      allow(described_class).to receive(:find_process_pids)
        .with("bin/shakapacker --watch")
        .and_return([12_345])
      allow(described_class).to receive(:shared_private_output_paths?).and_return(true)

      expect(described_class).to receive(:exec).with(
        { "RAILS_ENV" => "test", "CLIENT_BUNDLE_ONLY" => "true" },
        "bin/shakapacker",
        "--watch"
      )

      described_class.send(:run_test_watch, test_watch_mode: "auto")
    end

    it "accepts explicit full mode" do
      allow(described_class).to receive(:find_process_pids).and_return([12_345])

      expect(described_class).to receive(:exec).with({ "RAILS_ENV" => "test" }, "bin/shakapacker", "--watch")

      described_class.send(:run_test_watch, test_watch_mode: "full")
    end
  end

  describe ".extract_command_from_args" do
    it "treats --test-watch-mode value as a flag value, not a command" do
      command = described_class.send(:extract_command_from_args, ["--test-watch-mode", "client-only", "test-watch"])
      expect(command).to eq("test-watch")
    end
  end

  describe ".run_from_command_line with precompile hook" do
    before do
      mock_system_calls
      # Clear environment variable before each test
      ENV.delete("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
    end

    after do
      # Clean up environment variable after each test to ensure test isolation
      # This ensures cleanup even if tests fail
      ENV.delete("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
    end

    context "when precompile hook is configured" do
      before do
        # Default to a version that supports the skip flag (no warning)
        allow(ReactOnRails::PackerUtils).to receive_messages(
          shakapacker_precompile_hook_value: "bundle exec rake react_on_rails:locale", shakapacker_version: "9.4.0"
        )
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
          .with("9.0.0").and_return(true)
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
          .with("9.4.0").and_return(true)
      end

      it "runs the hook and sets environment variable for development mode" do
        status_double = instance_double(Process::Status, success?: true)
        expect(Open3).to receive(:capture3)
          .with("bundle", "exec", "rake", "react_on_rails:locale")
          .and_return(["", "", status_double])

        described_class.run_from_command_line([])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to eq("true")
      end

      it "runs the hook and sets environment variable for static mode" do
        status_double = instance_double(Process::Status, success?: true)
        expect(Open3).to receive(:capture3)
          .with("bundle", "exec", "rake", "react_on_rails:locale")
          .and_return(["", "", status_double])

        described_class.run_from_command_line(["static"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to eq("true")
      end

      it "runs the hook and sets environment variable for prod mode" do
        env = { "NODE_ENV" => "production" }
        argv = ["bundle", "exec", "rails", "assets:precompile"]
        assets_status_double = instance_double(Process::Status, success?: true)
        hook_status_double = instance_double(Process::Status, success?: true)

        # Expect both Open3.capture3 calls: one for the hook, one for assets:precompile
        expect(Open3).to receive(:capture3)
          .with("bundle", "exec", "rake", "react_on_rails:locale")
          .and_return(["", "", hook_status_double])
        expect(Open3).to receive(:capture3)
          .with(env, *argv)
          .and_return(["output", "", assets_status_double])

        described_class.run_from_command_line(["prod"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to eq("true")
      end

      it "exits when hook fails" do
        status_double = instance_double(Process::Status, success?: false)
        expect(Open3).to receive(:capture3)
          .with("bundle", "exec", "rake", "react_on_rails:locale")
          .and_return(["", "", status_double])
        expect_any_instance_of(Kernel).to receive(:exit).with(1)

        described_class.run_from_command_line([])
      end

      it "does not run hook or set environment variable for kill command" do
        expect(Open3).not_to receive(:capture3)

        described_class.run_from_command_line(["kill"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to be_nil
      end

      it "does not run hook or set environment variable for clean command" do
        expect(Open3).not_to receive(:capture3)
        expect(described_class).to receive(:clean_generated_assets_and_caches)

        described_class.run_from_command_line(["clean"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to be_nil
      end

      it "does not run hook or set environment variable for help command" do
        expect(Open3).not_to receive(:capture3)

        described_class.run_from_command_line(["help"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to be_nil
      end

      it "does not run hook or set environment variable for -h flag" do
        expect(Open3).not_to receive(:capture3)

        # The -h flag is handled by OptionParser and calls exit during option parsing
        # We need to mock exit to prevent the test from actually exiting
        allow_any_instance_of(Kernel).to receive(:exit)

        described_class.run_from_command_line(["-h"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to be_nil
      end

      context "with Shakapacker version below 9.4.0" do
        before do
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version).and_return("9.3.0")
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("9.0.0").and_return(true)
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("9.4.0").and_return(false)
        end

        it "displays version warning for direct command hooks" do
          # Direct command hooks can't self-guard, so the version warning is shown
          allow(ReactOnRails::PackerUtils).to receive_messages(hook_script_has_self_guard?: false,
                                                               resolve_hook_script_path: nil)

          status_double = instance_double(Process::Status, success?: true)
          expect(Open3).to receive(:capture3)
            .with("bundle", "exec", "rake", "react_on_rails:locale")
            .and_return(["", "", status_double])

          expect do
            described_class.run_from_command_line([])
          end.to output(/Warning: Shakapacker 9\.3\.0 detected/).to_stdout_from_any_process

          expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to eq("true")
        end

        it "displays self-guard warning for script hooks missing the guard" do
          hook_path = Pathname.new("/app/bin/shakapacker-precompile-hook")
          allow(ReactOnRails::PackerUtils).to receive_messages(
            hook_script_has_self_guard?: false,
            resolve_hook_script_path: hook_path
          )

          status_double = instance_double(Process::Status, success?: true)
          expect(Open3).to receive(:capture3)
            .with("bundle", "exec", "rake", "react_on_rails:locale")
            .and_return(["", "", status_double])

          expect do
            described_class.run_from_command_line([])
          end.to output(/missing the self-guard line/).to_stdout_from_any_process
        end

        it "does not display warning for script hooks with self-guard" do
          allow(ReactOnRails::PackerUtils).to receive(:hook_script_has_self_guard?).and_return(true)

          status_double = instance_double(Process::Status, success?: true)
          expect(Open3).to receive(:capture3)
            .with("bundle", "exec", "rake", "react_on_rails:locale")
            .and_return(["", "", status_double])

          expect do
            described_class.run_from_command_line([])
          end.not_to output(/Warning/).to_stdout_from_any_process
        end
      end

      context "with Shakapacker version 9.4.0 or later" do
        before do
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version).and_return("9.4.0")
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("9.0.0").and_return(true)
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("9.4.0").and_return(true)
        end

        it "does not display warning" do
          status_double = instance_double(Process::Status, success?: true)
          expect(Open3).to receive(:capture3)
            .with("bundle", "exec", "rake", "react_on_rails:locale")
            .and_return(["", "", status_double])

          expect do
            described_class.run_from_command_line([])
          end.not_to output(/Warning: Shakapacker/).to_stdout_from_any_process
        end
      end
    end

    context "when no precompile hook is configured" do
      before do
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_value).and_return(nil)
      end

      it "sets environment variable even when no hook is configured (provides consistent signal)" do
        # The environment variable is intentionally set even when no hook exists
        # to provide a consistent signal that bin/dev is managing the precompile lifecycle
        expect_any_instance_of(Kernel).not_to receive(:system)

        described_class.run_from_command_line([])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to eq("true")
      end

      it "does not set environment variable for kill command" do
        described_class.run_from_command_line(["kill"])

        expect(ENV.fetch("SHAKAPACKER_SKIP_PRECOMPILE_HOOK", nil)).to be_nil
      end
    end
  end

  # These tests verify argument parsing works correctly, following Rails' CLI testing pattern
  # See: https://github.com/rails/rails/blob/main/railties/test/commands/server_test.rb
  describe ".run_from_command_line argument parsing" do
    before do
      mock_system_calls
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_value).and_return(nil)
      allow(ReactOnRails::Dev::ServiceChecker).to receive(:check_services).and_return(true)
    end

    context "with --route flag" do
      # This test would have caught the bug fixed in PR #2273
      # The generator creates bin/dev with: argv_with_defaults.push("--route", DEFAULT_ROUTE)
      # which passes ["--route", "hello_world"] to run_from_command_line
      it "correctly parses --route with value as separate argument (generator default)" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(route: "hello_world", verbose: false)
        )

        described_class.run_from_command_line(["--route", "hello_world"])
      end

      it "correctly parses --route=value syntax" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(route: "hello_world")
        )

        described_class.run_from_command_line(["--route=hello_world"])
      end

      it "correctly parses command before --route flag" do
        expect(described_class).to receive(:start).with(
          :static,
          "Procfile.dev-static-assets",
          hash_including(route: "myroute")
        )

        described_class.run_from_command_line(["static", "--route", "myroute"])
      end

      it "correctly parses command after --route flag" do
        expect(described_class).to receive(:start).with(
          :static,
          "Procfile.dev-static-assets",
          hash_including(route: "myroute")
        )

        described_class.run_from_command_line(["--route", "myroute", "static"])
      end

      it "does not treat route value as a command" do
        # This is the core bug test - "hello_world" should NOT be treated as a command
        expect(described_class).not_to receive(:start).with(:unknown, anything, anything)

        # Should start development mode (default), not fail with "Unknown argument: hello_world"
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(route: "hello_world")
        )

        described_class.run_from_command_line(["--route", "hello_world"])
      end
    end

    context "with --rails-env flag" do
      it "correctly parses --rails-env with value as separate argument" do
        env = { "NODE_ENV" => "production", "RAILS_ENV" => "staging" }
        argv = ["bundle", "exec", "rails", "assets:precompile"]
        status_double = instance_double(Process::Status, success?: true)
        expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])

        described_class.run_from_command_line(["prod", "--rails-env", "staging"])
      end

      it "does not treat rails-env value as a command" do
        env = { "NODE_ENV" => "production", "RAILS_ENV" => "production" }
        argv = ["bundle", "exec", "rails", "assets:precompile"]
        status_double = instance_double(Process::Status, success?: true)
        expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])

        # "production" after --rails-env should not be treated as a command
        described_class.run_from_command_line(["--rails-env", "production", "prod"])
      end
    end

    context "with --verbose flag" do
      it "correctly parses --verbose flag" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(verbose: true)
        )

        described_class.run_from_command_line(["--verbose"])
      end

      it "correctly parses -v short flag" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(verbose: true)
        )

        described_class.run_from_command_line(["-v"])
      end
    end

    context "with multiple flags" do
      it "correctly parses command with multiple flags" do
        expect(described_class).to receive(:start).with(
          :static,
          "Procfile.dev-static-assets",
          hash_including(route: "dashboard", verbose: true)
        )

        described_class.run_from_command_line(["static", "--route", "dashboard", "--verbose"])
      end

      it "correctly parses flags in any order" do
        expect(described_class).to receive(:start).with(
          :static,
          "Procfile.dev-static-assets",
          hash_including(route: "dashboard", verbose: true)
        )

        described_class.run_from_command_line(["--verbose", "--route", "dashboard", "static"])
      end
    end

    context "with browser flags" do
      it "passes --open-browser to start" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(open_browser: true, open_browser_once: false)
        )

        described_class.run_from_command_line(["--open-browser"])
      end

      it "passes --open-browser-once to start" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(open_browser: false, open_browser_once: true)
        )

        described_class.run_from_command_line(["--open-browser-once"])
      end

      it "lets later browser flags win when --open-browser-once comes last" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(open_browser: false, open_browser_once: true)
        )

        described_class.run_from_command_line(["--open-browser", "--open-browser-once"])
      end

      it "lets later browser flags win when --open-browser comes last" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(open_browser: true, open_browser_once: false)
        )

        described_class.run_from_command_line(["--open-browser-once", "--open-browser"])
      end

      it "lets --no-open-browser override generated auto-open flags" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(open_browser: false, open_browser_once: false)
        )

        described_class.run_from_command_line(["--open-browser-once", "--no-open-browser"])
      end
    end

    context "with no arguments (default mode)" do
      it "starts development mode with no route" do
        expect(described_class).to receive(:start).with(
          :development,
          "Procfile.dev",
          hash_including(route: nil, verbose: false)
        )

        described_class.run_from_command_line([])
      end
    end

    context "with unknown command" do
      it "rejects and shows error message" do
        expect_any_instance_of(Kernel).to receive(:exit).with(1)

        expect do
          described_class.run_from_command_line(["invalid_command"])
        end.to output("Unknown argument: invalid_command\nRun 'dev help' for usage information\n").to_stdout
      end
    end
  end

  describe ".schedule_browser_open" do
    let(:marker_dir) { Dir.mktmpdir }

    around do |example|
      example.run
    ensure
      FileUtils.remove_entry(marker_dir)
    end

    before do
      marker_path = File.join(marker_dir, "browser_opened_once")
      allow(described_class).to receive(:open_browser_once_marker).and_return(marker_path)
      allow(described_class).to receive_messages(
        browser_auto_open_allowed?: true,
        wait_for_app_route: true
      )
    end

    it "warns when automatic browser opening fails" do
      allow(described_class).to receive(:open_browser).and_return(false)
      expect(described_class).to receive(:warn).with(
        a_string_matching(
          %r{\A\[react_on_rails\] Could not open browser automatically\..* Visit http://localhost:3000 manually\.\z}
        )
      )

      described_class.send(:schedule_browser_open, 3000, route: "/", once: false).join
    end

    it "warns when the browser-open thread raises unexpectedly" do
      allow(described_class).to receive(:wait_for_app_route).and_raise(SocketError, "boom")
      expect(described_class).to receive(:warn).with("[react_on_rails] Browser auto-open failed: boom")

      described_class.send(:schedule_browser_open, 3000, route: "/", once: false).join
    end

    it "does not open the browser again after the once marker is claimed" do
      allow(described_class).to receive(:open_browser).and_return(true)

      described_class.send(:schedule_browser_open, 3000, route: "/", once: true).join
      described_class.send(:schedule_browser_open, 3000, route: "/", once: true).join

      expect(described_class).to have_received(:open_browser).once
    end

    it "removes a claimed once marker when browser opening fails" do
      allow(described_class).to receive(:open_browser).and_return(false)
      allow(described_class).to receive(:warn)

      described_class.send(:schedule_browser_open, 3000, route: "/", once: true).join

      expect(File.exist?(described_class.send(:open_browser_once_marker))).to be(false)
    end
  end

  describe ".print_server_info" do
    it "normalizes root routes without a double slash" do
      expect do
        described_class.send(:print_server_info, "Title", ["Feature"], 3000, route: "/")
      end.to output(%r{http://localhost:3000(?!/)}).to_stdout_from_any_process
    end

    it "normalizes routes passed with a leading slash" do
      expect do
        described_class.send(:print_server_info, "Title", ["Feature"], 3000, route: "/hello_world")
      end.to output(%r{http://localhost:3000/hello_world}).to_stdout_from_any_process
    end
  end
end
