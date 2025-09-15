# frozen_string_literal: true

require "spec_helper"

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
      allow(IO).to receive(:popen).with("overmind -v").and_return("Some version info")
      expect(described_class.installed?("overmind")).to be_truthy
    end

    it "returns false when process is not available" do
      allow(IO).to receive(:popen).with("nonexistent -v").and_raise(Errno::ENOENT)
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
    end

    it "uses overmind when available" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("overmind start -f Procfile.dev")

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "uses foreman when overmind not available" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(false)
      allow(described_class).to receive(:installed?).with("foreman").and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("foreman start -f Procfile.dev")

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "exits with error when no process manager available" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(false)
      allow(described_class).to receive(:installed?).with("foreman").and_return(false)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)

      described_class.run_with_process_manager("Procfile.dev")
    end

    it "cleans up stale files before starting" do
      allow(described_class).to receive(:installed?).with("overmind").and_return(true)
      expect(ReactOnRails::Dev::FileManager).to receive(:cleanup_stale_files)

      described_class.run_with_process_manager("Procfile.dev")
    end
  end
end
