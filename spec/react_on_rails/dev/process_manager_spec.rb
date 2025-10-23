# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/process_manager"

RSpec.describe ReactOnRails::Dev::ProcessManager do
  describe ".installed?" do
    it "returns true when process is available in current context" do
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).and_yield
      expect_any_instance_of(Kernel).to receive(:system)
        .with("overmind", "--version", out: File::NULL, err: File::NULL).and_return(true)
      expect(described_class).to be_installed("overmind")
    end

    it "returns false when process is not available in current context" do
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).and_raise(Errno::ENOENT)
      expect(described_class.installed?("nonexistent")).to be false
    end

    it "returns false when all version flags fail" do
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).exactly(3).times.and_yield
      expect_any_instance_of(Kernel).to receive(:system)
        .with("failing_process", "--version", out: File::NULL, err: File::NULL).and_return(false)
      expect_any_instance_of(Kernel).to receive(:system)
        .with("failing_process", "-v", out: File::NULL, err: File::NULL).and_return(false)
      expect_any_instance_of(Kernel).to receive(:system)
        .with("failing_process", "-V", out: File::NULL, err: File::NULL).and_return(false)
      expect(described_class.installed?("failing_process")).to be false
    end

    it "returns true when second version flag succeeds" do
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).twice.and_yield
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "--version", out: File::NULL, err: File::NULL).and_return(false)
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "-v", out: File::NULL, err: File::NULL).and_return(true)
      expect(described_class.installed?("foreman")).to be true
    end

    it "returns false when version check times out" do
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).and_raise(Timeout::Error)
      expect(described_class.installed?("hanging_process")).to be false
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
      expect(described_class).to receive(:run_process_if_available)
        .with("overmind", ["start", "-f", "Procfile.dev"]).and_return(true)

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "uses foreman when overmind not available and foreman is available" do
      expect(described_class).to receive(:run_process_if_available)
        .with("overmind", ["start", "-f", "Procfile.dev"]).and_return(false)
      expect(described_class).to receive(:run_process_if_available)
        .with("foreman", ["start", "-f", "Procfile.dev"]).and_return(true)

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "exits with error when no process manager available" do
      expect(described_class).to receive(:run_process_if_available)
        .with("overmind", ["start", "-f", "Procfile.dev"]).and_return(false)
      expect(described_class).to receive(:run_process_if_available)
        .with("foreman", ["start", "-f", "Procfile.dev"]).and_return(false)
      expect(described_class).to receive(:show_process_manager_installation_help)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "cleans up stale files before starting" do
      allow(described_class).to receive(:run_process_if_available).and_return(true)
      expect(ReactOnRails::Dev::FileManager).to receive(:cleanup_stale_files)

      described_class.run_with_process_manager("Procfile.dev")
    end
  end

  describe ".run_process_if_available" do
    it "returns true and runs process when available in current context" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev").and_return(true)

      result = described_class.send(:run_process_if_available, "foreman", ["start", "-f", "Procfile.dev"])
      expect(result).to be true
    end

    it "tries system context when not available in current context" do
      allow(described_class).to receive(:installed?).with("foreman").and_return(false)
      allow(described_class).to receive(:process_available_in_system?).with("foreman").and_return(true)
      expect(described_class).to receive(:run_process_outside_bundle)
        .with("foreman", ["start", "-f", "Procfile.dev"]).and_return(true)

      result = described_class.send(:run_process_if_available, "foreman", ["start", "-f", "Procfile.dev"])
      expect(result).to be true
    end

    it "returns false when process not available anywhere" do
      allow(described_class).to receive(:installed?).with("nonexistent").and_return(false)
      allow(described_class).to receive(:process_available_in_system?).with("nonexistent").and_return(false)

      result = described_class.send(:run_process_if_available, "nonexistent", ["start"])
      expect(result).to be false
    end
  end

  describe ".run_process_outside_bundle" do
    it "uses with_unbundled_context when Bundler is available" do
      expect(described_class).to receive(:with_unbundled_context).and_yield
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev")

      described_class.send(:run_process_outside_bundle, "foreman", ["start", "-f", "Procfile.dev"])
    end

    it "falls back to direct system call when Bundler is not available" do
      hide_const("Bundler")
      expect_any_instance_of(Kernel).to receive(:system).with("foreman", "start", "-f", "Procfile.dev")

      described_class.send(:run_process_outside_bundle, "foreman", ["start", "-f", "Procfile.dev"])
    end
  end

  describe ".process_available_in_system?" do
    it "checks process availability outside bundle context with version flags" do
      expect(described_class).to receive(:with_unbundled_context).and_yield
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).and_yield
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "--version", out: File::NULL, err: File::NULL).and_return(true)

      expect(described_class.send(:process_available_in_system?, "foreman")).to be true
    end

    it "returns false when Bundler is not available" do
      hide_const("Bundler")

      expect(described_class.send(:process_available_in_system?, "foreman")).to be false
    end

    it "tries multiple version flags before failing" do
      expect(described_class).to receive(:with_unbundled_context).and_yield
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).twice.and_yield
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "--version", out: File::NULL, err: File::NULL).and_return(false)
      expect_any_instance_of(Kernel).to receive(:system)
        .with("foreman", "-v", out: File::NULL, err: File::NULL).and_return(true)

      expect(described_class.send(:process_available_in_system?, "foreman")).to be true
    end

    it "returns false when version check times out in system context" do
      expect(described_class).to receive(:with_unbundled_context).and_yield
      expect(Timeout).to receive(:timeout).with(described_class::VERSION_CHECK_TIMEOUT).and_raise(Timeout::Error)

      expect(described_class.send(:process_available_in_system?, "hanging_process")).to be false
    end
  end

  describe ".version_flags_for" do
    it "returns specific flags for overmind" do
      expect(described_class.send(:version_flags_for, "overmind")).to eq(["--version"])
    end

    it "returns multiple flags for foreman" do
      expect(described_class.send(:version_flags_for, "foreman")).to eq(["--version", "-v"])
    end

    it "returns generic flags for unknown processes" do
      expect(described_class.send(:version_flags_for, "unknown")).to eq(["--version", "-v", "-V"])
    end
  end

  describe ".with_unbundled_context" do
    it "uses with_unbundled_env when available" do
      bundler_double = class_double(Bundler)
      stub_const("Bundler", bundler_double)
      allow(bundler_double).to receive(:respond_to?).with(:with_unbundled_env).and_return(true)
      expect(bundler_double).to receive(:with_unbundled_env).and_yield

      yielded = false
      described_class.send(:with_unbundled_context) { yielded = true }
      expect(yielded).to be true
    end

    it "falls back to with_clean_env when with_unbundled_env not available" do
      bundler_double = class_double(Bundler)
      stub_const("Bundler", bundler_double)
      allow(bundler_double).to receive(:respond_to?).with(:with_unbundled_env).and_return(false)
      allow(bundler_double).to receive(:respond_to?).with(:with_clean_env).and_return(true)
      expect(bundler_double).to receive(:with_clean_env).and_yield

      yielded = false
      described_class.send(:with_unbundled_context) { yielded = true }
      expect(yielded).to be true
    end

    it "yields directly when neither method is available" do
      bundler_double = class_double(Bundler)
      stub_const("Bundler", bundler_double)
      allow(bundler_double).to receive(:respond_to?).with(:with_unbundled_env).and_return(false)
      allow(bundler_double).to receive(:respond_to?).with(:with_clean_env).and_return(false)

      yielded = false
      described_class.send(:with_unbundled_context) { yielded = true }
      expect(yielded).to be true
    end
  end

  describe ".show_process_manager_installation_help" do
    it "displays helpful error message with installation instructions" do
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/ERROR: Process Manager Not Found/).to_stderr
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/DO NOT add foreman to your Gemfile/).to_stderr
      expect { described_class.send(:show_process_manager_installation_help) }
        .to output(/Don't-Bundle-Foreman/).to_stderr
    end
  end
end
