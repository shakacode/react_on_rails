# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/port_selector"
require "socket"

RSpec.describe ReactOnRails::Dev::PortSelector do
  describe ".select_ports" do
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

      it "does not print a shift message" do
        allow(described_class).to receive(:port_available?).and_return(true)
        expect { described_class.select_ports }.not_to output(/shifted/i).to_stdout
      end
    end

    context "when default ports are occupied" do
      it "finds the next free Rails port" do
        call_count = 0
        allow(described_class).to receive(:port_available?) do
          call_count += 1
          call_count > 1 # first check (3000) fails; && short-circuits so 3035 is never checked
        end
        result = described_class.select_ports
        expect(result[:rails]).to eq(3001)
      end

      it "keeps webpack port offset from Rails port" do
        call_count = 0
        allow(described_class).to receive(:port_available?) do
          call_count += 1
          call_count > 1
        end
        result = described_class.select_ports
        expect(result[:webpack]).to eq(3036)
      end

      it "prints a message when ports are shifted" do
        call_count = 0
        allow(described_class).to receive(:port_available?) do
          call_count += 1
          call_count > 1
        end
        expect { described_class.select_ports }.to output(/3001.*3036|shifted|in use/i).to_stdout
      end
    end

    context "when ENV['PORT'] is already set" do
      around do |example|
        old = ENV.fetch("PORT", nil)
        ENV["PORT"] = "4000"
        example.run
        ENV["PORT"] = old
      end

      it "respects the existing PORT env var" do
        result = described_class.select_ports
        expect(result[:rails]).to eq(4000)
      end

      it "does not probe for free ports" do
        expect(described_class).not_to receive(:port_available?)
        described_class.select_ports
      end
    end

    context "when ENV['SHAKAPACKER_DEV_SERVER_PORT'] is already set" do
      around do |example|
        old = ENV.fetch("SHAKAPACKER_DEV_SERVER_PORT", nil)
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = "4035"
        example.run
        ENV["SHAKAPACKER_DEV_SERVER_PORT"] = old
      end

      it "respects the existing SHAKAPACKER_DEV_SERVER_PORT env var" do
        result = described_class.select_ports
        expect(result[:webpack]).to eq(4035)
      end
    end

    context "when no port is available within max attempts" do
      it "raises an error" do
        allow(described_class).to receive(:port_available?).and_return(false)
        expect { described_class.select_ports }.to raise_error(described_class::NoPortAvailable, /No available port/)
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

    it "returns false for a port that is already in use" do
      server = TCPServer.new("127.0.0.1", 0)
      occupied_port = server.addr[1]
      begin
        expect(described_class.port_available?(occupied_port)).to be false
      ensure
        server.close
      end
    end
  end
end
