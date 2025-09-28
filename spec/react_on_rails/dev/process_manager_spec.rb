# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/process_manager"

RSpec.describe ReactOnRails::Dev::ProcessManager do
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

  describe ".installed?" do
    it "returns true when process is available" do
      allow(IO).to receive(:popen).with(["overmind", "-v"]).and_return("Some version info")
      expect(described_class).to be_installed("overmind")
    end

    it "returns false when process is not available" do
      allow(IO).to receive(:popen).with(["nonexistent", "-v"]).and_raise(Errno::ENOENT)
      expect(described_class.installed?("nonexistent")).to be false
    end
  end

  describe ".ensure_procfile" do
    it "does nothing when Procfile exists" do
      allow(File).to receive(:exist?).with("Procfile.dev").and_return(true)
      expect { described_class.ensure_procfile("Procfile.dev") }.not_to raise_error
    end

    it "exits with error when Procfile does not exist" do
      allow(File).to receive(:exist?).with("Procfile.dev").and_return(false)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.ensure_procfile("Procfile.dev")
    end
  end

  describe ".run_with_process_manager" do
    before do
      allow(ReactOnRails::Dev::FileManager).to receive(:cleanup_stale_files)
      allow_any_instance_of(Kernel).to receive(:system).and_return(true)
      allow(File).to receive(:readable?).and_return(true)
    end

    it "uses overmind when available" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("overmind", "start", "-f", "Procfile.dev")

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "uses foreman when overmind not available and foreman is in bundle" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(false)
      allow(described_class).to receive(:foreman_available?).and_return(true)
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      expect(described_class).to receive(:run_foreman).with("Procfile.dev")

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "exits with error when no process manager available" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(false)
      allow(described_class).to receive(:foreman_available?).and_return(false)
      expect(described_class).to receive(:show_process_manager_installation_help)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "cleans up stale files before starting" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(true)
      expect(ReactOnRails::Dev::FileManager).to receive(:cleanup_stale_files)

      described_class.run_with_process_manager("Procfile.dev")
    end
  end

  describe ".foreman_available?" do
    it "returns true when foreman is available in bundle context" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      allow(described_class).to receive(:foreman_available_in_system?).and_return(false)

      expect(described_class.send(:foreman_available?)).to be true
    end

    it "returns true when foreman is available system-wide" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(false)
      allow(described_class).to receive(:foreman_available_in_system?).and_return(true)

      expect(described_class.send(:foreman_available?)).to be true
    end

    it "returns false when foreman is not available anywhere" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(false)
      allow(described_class).to receive(:foreman_available_in_system?).and_return(false)

      expect(described_class.send(:foreman_available?)).to be false
    end
  end

  describe ".run_foreman" do
    before do
      allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    end

    it "tries bundle context first when foreman is in bundle" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev").and_return(true)
      expect(described_class).not_to receive(:run_foreman_outside_bundle)

      described_class.send(:run_foreman, "Procfile.dev")
    end

    it "falls back to system foreman when bundle context fails" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "start", "-f", "Procfile.dev").and_return(false)
      expect(described_class).to receive(:run_foreman_outside_bundle).with("Procfile.dev")

      described_class.send(:run_foreman, "Procfile.dev")
    end

    it "uses system foreman directly when not in bundle" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(false)
      expect(described_class).to receive(:run_foreman_outside_bundle).with("Procfile.dev")

      described_class.send(:run_foreman, "Procfile.dev")
    end
  end

  describe ".run_foreman_outside_bundle" do
    it "uses Bundler.with_unbundled_env when Bundler is available" do
      bundler_double = class_double(Bundler)
      stub_const("Bundler", bundler_double)
      expect(bundler_double).to receive(:with_unbundled_env).and_yield
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev")

      described_class.send(:run_foreman_outside_bundle, "Procfile.dev")
    end

    it "falls back to direct system call when Bundler is not available" do
      hide_const("Bundler")
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev")

      described_class.send(:run_foreman_outside_bundle, "Procfile.dev")
    end
  end

  describe ".foreman_available_in_system?" do
    it "checks foreman availability outside bundle context" do
      bundler_double = class_double(Bundler)
      stub_const("Bundler", bundler_double)
      expect(bundler_double).to receive(:with_unbundled_env).and_yield
      expect(described_class).to receive(:installed?).with("foreman").and_return(true)

      expect(described_class.send(:foreman_available_in_system?)).to be true
    end

    it "returns false when Bundler is not available" do
      hide_const("Bundler")

      expect(described_class.send(:foreman_available_in_system?)).to be false
    end
  end

  describe ".show_process_manager_installation_help" do
    it "displays helpful error message with installation instructions" do
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/ERROR: Process Manager Not Found/).to_stderr
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/DO NOT add foreman to your Gemfile/).to_stderr
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/foreman-issues\.md/).to_stderr
    end
  end
end
