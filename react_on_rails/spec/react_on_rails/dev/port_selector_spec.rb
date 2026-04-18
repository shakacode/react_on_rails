# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/port_selector"
require "socket"

RSpec.describe ReactOnRails::Dev::PortSelector do
  # Every test in this file must start from a clean slate for the env vars
  # that influence port selection; otherwise a value leaked from the outer
  # shell (e.g. a developer running specs inside a Conductor workspace, or an
  # agent that set REACT_ON_RAILS_BASE_PORT) can silently change what
  # `select_ports` returns and cause tests to fail. Individual contexts set
  # the vars they actually want under test inside their own `around` blocks.
  around do |example|
    saved = {}
    %w[REACT_ON_RAILS_BASE_PORT CONDUCTOR_PORT PORT SHAKAPACKER_DEV_SERVER_PORT].each do |k|
      saved[k] = ENV.fetch(k, nil)
      ENV.delete(k)
    end
    example.run
  ensure
    # `saved` is assigned on the first line above and cannot fail, but guard with
    # `&.` so the ensure remains correct even if a future change moves the
    # assignment below something that can raise.
    saved&.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe ".select_ports" do
    context "when REACT_ON_RAILS_BASE_PORT is set" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "5000"
        example.run
      end

      # Keep derived-port warnings out of tests that don't specifically assert them.
      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "derives Rails port from base + 0" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(5000)
      end

      it "derives webpack port from base + 1" do
        result = described_class.select_ports
        expect(result[:webpack]).to eq(5001)
      end

      it "derives renderer port from base + 2" do
        result = described_class.select_ports
        expect(result[:renderer]).to eq(5002)
      end

      it "sets base_port_mode: true on the returned hash" do
        result = described_class.select_ports
        expect(result[:base_port_mode]).to be(true)
      end

      it "returns derived ports even when they are already in use (deterministic)" do
        allow(described_class).to receive(:port_available?).and_return(false)
        result = nil
        expect { result = described_class.select_ports }.to output(/already in use/).to_stderr
        expect(result).to include(rails: 5000, webpack: 5001, renderer: 5002)
      end

      it "prints a base port message" do
        expect { described_class.select_ports }.to output(/Base port 5000 detected/).to_stdout
      end

      it "names the source env var in the base port log line" do
        expect { described_class.select_ports }.to output(/via REACT_ON_RAILS_BASE_PORT/).to_stdout
      end
    end

    context "when CONDUCTOR_PORT is set (without REACT_ON_RAILS_BASE_PORT)" do
      around do |example|
        ENV["CONDUCTOR_PORT"] = "6000"
        example.run
      end

      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "derives all ports from CONDUCTOR_PORT" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(6000)
        expect(result[:webpack]).to eq(6001)
        expect(result[:renderer]).to eq(6002)
      end

      it "names CONDUCTOR_PORT as the source in the base port log line" do
        expect { described_class.select_ports }.to output(/via CONDUCTOR_PORT/).to_stdout
      end
    end

    context "when both REACT_ON_RAILS_BASE_PORT and CONDUCTOR_PORT are set" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "5000"
        ENV["CONDUCTOR_PORT"] = "6000"
        example.run
      end

      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "prefers REACT_ON_RAILS_BASE_PORT over CONDUCTOR_PORT" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(5000)
      end
    end

    context "when base port is out of range" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "99999"
        example.run
      end

      it "warns and falls back to normal auto-detection" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:renderer]).to be_nil
        end.to output(/out of range/).to_stderr
      end
    end

    context "when base port is zero" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "0"
        example.run
      end

      it "warns and falls back to auto-detection rather than deriving port 0" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:renderer]).to be_nil
        end.to output(/out of range/).to_stderr
      end
    end

    context "when base port is in the privileged range (1..1023)" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "80"
        example.run
      end

      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "still returns the derived ports (binding is the source of truth)" do
        result = nil
        expect { result = described_class.select_ports }.to output(/privileged range/).to_stderr
        expect(result[:rails]).to eq(80)
      end

      it "warns that binding will fail without root" do
        expect { described_class.select_ports }
          .to output(/privileged range \(1\.\.1023\); binding will fail without root/).to_stderr
      end
    end

    context "when base port is just above the privileged range" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "1024"
        example.run
      end

      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "does not emit the privileged-port warning" do
        expect { described_class.select_ports }.not_to output(/privileged range/).to_stderr
      end
    end

    context "when base port would push derived renderer port above 65535" do
      around do |example|
        # 65_534 + BASE_PORT_RENDERER_OFFSET (2) = 65_536, which is invalid.
        ENV["REACT_ON_RAILS_BASE_PORT"] = "65534"
        example.run
      end

      it "warns and falls back to auto-detection instead of deriving an invalid port" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:renderer]).to be_nil
        end.to output(/out of range/).to_stderr
      end
    end

    context "when base port is at the maximum safe value" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = described_class::MAX_BASE_PORT.to_s
        example.run
      end

      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "derives all three ports within the valid TCP range" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(described_class::MAX_BASE_PORT)
        expect(result[:webpack]).to eq(described_class::MAX_BASE_PORT + 1)
        expect(result[:renderer]).to eq(described_class::MAX_BASE_PORT + 2)
        expect(result[:renderer]).to be <= 65_535
      end
    end

    context "when base port env var is not a valid integer" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "400O" # letter O, not zero
        example.run
      end

      it "warns and falls back to auto-detection instead of silently parsing as 400" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:renderer]).to be_nil
        end.to output(/not a valid integer/).to_stderr
      end
    end

    context "when CONDUCTOR_PORT alone holds an invalid value" do
      around do |example|
        ENV["CONDUCTOR_PORT"] = "not-a-number"
        example.run
      end

      it "warns and falls back to auto-detection (mirrors REACT_ON_RAILS_BASE_PORT invalid handling)" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:renderer]).to be_nil
          expect(result[:base_port_mode]).to be(false)
        end.to output(/CONDUCTOR_PORT.*not a valid integer/).to_stderr
      end
    end

    context "when CONDUCTOR_PORT is out of range" do
      around do |example|
        ENV["CONDUCTOR_PORT"] = "70000"
        example.run
      end

      it "warns and falls back to auto-detection" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect do
          result = described_class.select_ports
          expect(result[:rails]).to eq(3000)
          expect(result[:base_port_mode]).to be(false)
        end.to output(/CONDUCTOR_PORT.*out of range/).to_stderr
      end
    end

    context "when REACT_ON_RAILS_BASE_PORT is invalid but CONDUCTOR_PORT is valid" do
      around do |example|
        ENV["REACT_ON_RAILS_BASE_PORT"] = "disabled"
        ENV["CONDUCTOR_PORT"] = "6000"
        example.run
      end

      # Stub so warn_if_derived_ports_in_use does not attempt real TCP probes
      # on 6000..6002 during tests (matches the pattern above).
      before { allow(described_class).to receive(:port_available?).and_return(true) }

      it "falls through to CONDUCTOR_PORT and activates base port mode" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(6000)
        expect(result[:base_port_mode]).to be(true)
      end

      it "warns that CONDUCTOR_PORT is still the active source so users can opt out" do
        expect { described_class.select_ports }
          .to output(/Base port mode will still activate from CONDUCTOR_PORT; unset to disable/).to_stderr
      end
    end

    context "when default ports are free" do
      it "returns the default Rails port 3000" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:rails]).to eq(3000)
      end

      it "returns the default webpack port 3035" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3035)
      end

      it "returns nil for renderer port" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:renderer]).to be_nil
      end

      it "does not print a shift message" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect { described_class.select_ports }.not_to output(/shifted/i).to_stdout
      end
    end

    context "when default ports are occupied" do
      it "finds the next free Rails port" do
        allow(described_class).to receive(:port_available?) do |port|
          port != 3000 # only 3000 is occupied
        end
        result = described_class.select_ports
        expect(result[:rails]).to eq(3001)
      end

      it "keeps webpack at its default when only the Rails default port is occupied" do
        allow(described_class).to receive(:port_available?) do |port|
          port != 3000 # 3035 is still free
        end
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3035)
      end

      it "increments webpack independently when both default ports are occupied" do
        allow(described_class).to receive(:port_available?) do |port|
          port != 3000 && port != 3035
        end
        result = described_class.select_ports
        expect(result[:rails]).to eq(3001)
        expect(result[:webpack]).to eq(3036)
      end

      it "prints a message when ports are shifted" do
        allow(described_class).to receive(:port_available?) do |port|
          port != 3000 && port != 3035
        end
        expect { described_class.select_ports }.to output(/3001.*3036|shifted|in use/i).to_stdout
      end
    end

    context "when ENV['PORT'] is already set" do
      around do |example|
        ENV["PORT"] = "4000"
        example.run
      end

      it "respects the existing PORT env var" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:rails]).to eq(4000)
      end

      it "defaults webpack to 3035 when SHAKAPACKER_DEV_SERVER_PORT is not set and 3035 is free" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3035)
      end

      it "finds next free webpack port when 3035 is occupied" do
        call_count = 0
        allow(described_class).to receive(:port_available?) do
          call_count += 1
          call_count > 1 # first check (3035) fails
        end
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3036)
      end

      it "does not return PORT value as webpack port when they would be equal" do
        ENV["PORT"] = "3035"
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:rails]).to eq(3035)
        expect(result[:webpack]).not_to eq(3035)
      end
    end

    context "when ENV['SHAKAPACKER_DEV_SERVER_PORT'] is already set" do
      around do |example|
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "4035"
        example.run
      end

      it "respects the existing SHAKAPACKER_DEV_SERVER_PORT env var" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:webpack]).to eq(4035)
      end

      it "defaults Rails to 3000 when PORT is not set and 3000 is free" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:rails]).to eq(3000)
      end

      it "finds next free rails port when 3000 is occupied" do
        call_count = 0
        allow(described_class).to receive(:port_available?) do
          call_count += 1
          call_count > 1 # first check (3000) fails
        end
        result = described_class.select_ports
        expect(result[:rails]).to eq(3001)
      end

      it "does not return SHAKAPACKER_DEV_SERVER_PORT value as rails port when they would be equal" do
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "3000"
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3000)
        expect(result[:rails]).not_to eq(3000)
      end
    end

    context "when both PORT and SHAKAPACKER_DEV_SERVER_PORT are set" do
      around do |example|
        ENV["PORT"] = "4000"
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "4035"
        example.run
      end

      it "returns both explicit ports" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(4000)
        expect(result[:webpack]).to eq(4035)
      end

      it "does not probe for free ports" do
        expect(described_class).not_to receive(:port_available?)
        described_class.select_ports
      end
    end

    context "when no port is available within max attempts" do
      it "raises an error" do
        allow(described_class).to receive(:port_available?).and_return(false)
        expect { described_class.select_ports }.to raise_error(described_class::NoPortAvailable, /No available port/)
      end
    end

    context "when PORT contains an out-of-range value" do
      around do |example|
        ENV["PORT"] = "99999"
        example.run
      end

      it "treats out-of-range PORT as unset and falls back to auto-detection" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = described_class.select_ports
        expect(result[:rails]).to eq(3000)
        expect(result[:webpack]).to eq(3035)
      end
    end

    # String#to_i would quietly turn "3000abc" into 3000, so the PortSelector
    # and apply_explicit_port_env paths diverged: PortSelector accepted the
    # truncated value, apply_explicit_port_env (strict regex) overwrote the
    # env var. Using the same all-digit check here keeps the two paths aligned.
    context "when PORT contains a non-numeric value" do
      around do |example|
        ENV["PORT"] = "3000abc"
        example.run
      end

      it "rejects PORT and falls back to auto-detection" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = nil
        expect { result = described_class.select_ports }
          .to output(/PORT=.*"3000abc".*not a valid integer/).to_stderr
        expect(result[:rails]).to eq(3000)
      end
    end

    context "when SHAKAPACKER_DEV_SERVER_PORT contains a non-numeric value" do
      around do |example|
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "3035xyz"
        example.run
      end

      it "rejects the value and falls back to auto-detection" do
        allow(described_class).to receive(:port_available?).and_return(true)
        result = nil
        expect { result = described_class.select_ports }
          .to output(/SHAKAPACKER_DEV_SERVER_PORT=.*"3035xyz".*not a valid integer/).to_stderr
        expect(result[:webpack]).to eq(3035)
      end
    end
  end

  describe ".port_available?" do
    it "returns true for a port that nothing is listening on" do
      # Find a definitely-free port using OS assignment, then close it and check
      server = TCPServer.new("127.0.0.1", 0)
      free_port = server.addr[1]
      server.close
      expect(described_class.port_available?(free_port)).to be true
    end

    it "returns false for a port that is already in use on IPv4" do
      server = TCPServer.new("127.0.0.1", 0)
      occupied_port = server.addr[1]
      begin
        expect(described_class.port_available?(occupied_port)).to be false
      ensure
        server.close
      end
    end

    it "returns false for a port that is already in use on IPv6 only" do
      server = TCPServer.new("::1", 0)
      occupied_port = server.addr[1]
      begin
        expect(described_class.port_available?(occupied_port)).to be false
      ensure
        server.close
      end
    end
  end
end
