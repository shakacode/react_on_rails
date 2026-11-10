# frozen_string_literal: true

require_relative "spec_helper"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe "SystemExitGuard" do
  let(:guard_path) { File.expand_path("support/system_exit_guard.rb", __dir__) }

  # Runs a throwaway spec file in a separate RSpec process. The fixture loads
  # only the guard, so the child skips Rails, SimpleCov, and this suite's
  # example status file.
  def run_fixture(body)
    Dir.mktmpdir("system-exit-guard") do |dir|
      fixture = File.join(dir, "fixture_spec.rb")
      File.write(fixture, <<~RUBY)
        require #{guard_path.dump}

        RSpec.describe "fixture" do
        #{body}
        end
      RUBY
      command = [RbConfig.ruby, Gem.bin_path("rspec-core", "rspec"), "--format", "progress", "--no-color", fixture]
      Open3.capture2e(*command, chdir: dir)
    end
  end

  it "fails an example that calls abort and keeps running later examples" do
    output, status = run_fixture(<<~RUBY)
      it("aborts") { abort "release helper gave up" }
      it("runs after the abort") { expect(1).to eq(1) }
    RUBY

    expect(status.success?).to be(false), output
    expect(output).to include("2 examples, 1 failure")
    expect(output).to include("SystemExitGuard::UnexpectedSystemExit")
    expect(output).to include("Exit message: release helper gave up")
  end

  it "fails an example that calls exit 0 instead of reporting a green run" do
    output, status = run_fixture(<<~RUBY)
      it("exits cleanly") { exit 0 }
      it("runs after the exit") { expect(1).to eq(1) }
    RUBY

    expect(status.success?).to be(false), output
    expect(output).to include("2 examples, 1 failure")
    expect(output).to include("Unexpected SystemExit (status 0)")
  end

  it "leaves expected and self-rescued exits passing" do
    output, status = run_fixture(<<~RUBY)
      it("expects the exit") { expect { abort "expected" }.to raise_error(SystemExit, "expected") }
      it "rescues the exit" do
        rescued = begin
          exit 2
        rescue SystemExit => e
          e.status
        end
        expect(rescued).to eq(2)
      end
      it "lets a bare forked child exit" do
        pid = Process.fork
        if pid.nil?
          # The child inherits RSpec, which prints its own summary on exit.
          $stdout.reopen(File::NULL)
          $stderr.reopen(File::NULL)
          exit 3
        end
        _, child_status = Process.wait2(pid)
        expect(child_status.exitstatus).to eq(3)
      end
    RUBY

    expect(status.success?).to be(true), output
    expect(output).to include("3 examples, 0 failures")
  end
end
