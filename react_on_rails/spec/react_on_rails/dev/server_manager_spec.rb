# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/server_manager"
require "open3"

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

  def mock_system_calls
    allow(ReactOnRails::Dev::PackGenerator).to receive(:generate).with(any_args)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager)
    allow(ReactOnRails::Dev::DatabaseChecker).to receive(:check_database).and_return(true)
  end

  describe ".start" do
    before { mock_system_calls }

    it "starts development mode by default" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

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

    it "starts production-like mode" do
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like)
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
  end

  describe ".kill_processes" do
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

      allow(File).to receive(:exist?).with(".overmind.sock").and_return(true)
      allow(File).to receive(:exist?).with("tmp/sockets/overmind.sock").and_return(false)
      allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)
      expect(File).to receive(:delete).with(".overmind.sock")

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

  describe ".show_help" do
    it "displays help information" do
      expect { described_class.show_help }.to output(%r{Usage: bin/dev \[command\]}).to_stdout_from_any_process
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
        expect_any_instance_of(Kernel).to receive(:puts).with("Unknown argument: invalid_command")
        expect_any_instance_of(Kernel).to receive(:puts).with("Run 'dev help' for usage information")
        expect_any_instance_of(Kernel).to receive(:exit).with(1)

        described_class.run_from_command_line(["invalid_command"])
      end
    end
  end
end
