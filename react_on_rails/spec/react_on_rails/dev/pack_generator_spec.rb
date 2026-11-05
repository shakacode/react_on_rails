# frozen_string_literal: true

require_relative "../spec_helper"
require "tmpdir"
require "react_on_rails/dev/pack_generator"

RSpec.describe ReactOnRails::Dev::PackGenerator do
  # Integration test: verify PackerUtils is properly required
  describe "module dependencies" do
    it "can access ReactOnRails::PackerUtils without errors" do
      # This test ensures the require statement is present in pack_generator.rb
      # If the require is missing, this will raise NameError: uninitialized constant
      expect { ReactOnRails::PackerUtils }.not_to raise_error
    end
  end

  describe ".generate" do
    context "when shakapacker precompile hook is configured" do
      before do
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_configured?).and_return(true)
      end

      it "skips pack generation in verbose mode" do
        expect { described_class.generate(verbose: true) }
          .to output(/⏭️  Skipping pack generation/).to_stdout_from_any_process
      end

      it "skips pack generation silently in quiet mode" do
        expect { described_class.generate(verbose: false) }
          .not_to output.to_stdout_from_any_process
      end

      it "does not invoke the rake task" do
        # Mock the task to ensure it's not called
        mock_task = instance_double(Rake::Task)
        allow(Rake::Task).to receive(:[]).with("react_on_rails:generate_packs").and_return(mock_task)
        allow(mock_task).to receive(:invoke)

        described_class.generate(verbose: false)

        expect(mock_task).not_to have_received(:invoke)
      end
    end

    context "when in Bundler context with Rails available" do
      let(:mock_task) { instance_double(Rake::Task) }
      let(:mock_rails_app) do
        # rubocop:disable RSpec/VerifiedDoubles
        double("Rails.application").tap do |app|
          allow(app).to receive(:load_tasks)
          allow(app).to receive(:respond_to?).with(:load_tasks).and_return(true)
        end
        # rubocop:enable RSpec/VerifiedDoubles
      end

      before do
        # Ensure precompile hook is not configured for these tests
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_configured?).and_return(false)

        # Setup Bundler context
        stub_const("Bundler", Module.new)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return("/path/to/Gemfile")

        # Setup Rails availability
        app = mock_rails_app
        rails_module = Module.new do
          define_singleton_method(:application) { app }
          define_singleton_method(:respond_to?) { |method, *| method == :application }
        end
        stub_const("Rails", rails_module)

        # Mock Rake::Task at the boundary
        allow(Rake::Task).to receive(:task_defined?).with("react_on_rails:generate_packs").and_return(false)
        allow(Rake::Task).to receive(:[]).with("react_on_rails:generate_packs").and_return(mock_task)
        allow(mock_task).to receive(:reenable)
        allow(mock_task).to receive(:invoke)
      end

      it "runs pack generation successfully in verbose mode using direct rake execution" do
        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process

        expect(mock_task).to have_received(:invoke)
        expect(mock_rails_app).to have_received(:load_tasks)
      end

      it "runs pack generation successfully in quiet mode using direct rake execution" do
        expect { described_class.generate(verbose: false) }
          .to output(/📦 Generating packs\.\.\. ✅/).to_stdout_from_any_process

        expect(mock_task).to have_received(:invoke)
      end

      it "exits with error when pack generation fails" do
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Task failed"))

        # Mock STDERR.puts to capture output
        error_output = []
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts) { |msg| error_output << msg }
        # rubocop:enable Style/GlobalStdStream

        expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
        expect(error_output.join("\n")).to match(/Error generating packs: Task failed/)
      end

      it "suggests --verbose flag when pack generation fails in quiet mode" do
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Task failed"))

        # Mock STDERR.puts to suppress error output
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts)
        # rubocop:enable Style/GlobalStdStream

        expect { described_class.generate(verbose: false) }
          .to output(/Run with.*--verbose.*flag for detailed output/).to_stdout_from_any_process
          .and raise_error(SystemExit)
      end

      it "does not suggest --verbose flag when already in verbose mode" do
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Task failed"))

        # Mock STDERR.puts to suppress error output
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts)
        # rubocop:enable Style/GlobalStdStream

        # Capture output to verify --verbose suggestion is not shown
        output = StringIO.new
        # rubocop:disable RSpec/ExpectOutput
        begin
          $stdout = output
          described_class.generate(verbose: true)
        rescue SystemExit
          # Expected to exit
        ensure
          $stdout = STDOUT
        end
        # rubocop:enable RSpec/ExpectOutput

        expect(output.string).not_to match(/Run with.*--verbose/)
      end

      it "outputs errors to stderr even in silent mode" do
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Silent mode error"))

        # Mock STDERR.puts to capture output
        error_output = []
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts) { |msg| error_output << msg }
        # rubocop:enable Style/GlobalStdStream

        expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
        expect(error_output.join("\n")).to match(/Error generating packs: Silent mode error/)
      end

      it "includes backtrace in error output when DEBUG env is set" do
        allow(ENV).to receive(:[]).with("DEBUG").and_return("true")
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Debug error"))

        # Mock STDERR.puts to capture output
        error_output = []
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts) { |msg| error_output << msg }
        # rubocop:enable Style/GlobalStdStream

        expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
        expect(error_output.join("\n")).to match(/Error generating packs: Debug error.*pack_generator_spec\.rb/m)
      end

      it "suppresses stdout in silent mode" do
        # Mock task to produce output
        allow(mock_task).to receive(:invoke) do
          puts "This should be suppressed"
        end

        expect { described_class.generate(verbose: false) }
          .not_to output(/This should be suppressed/).to_stdout_from_any_process
      end

      it "sets REACT_ON_RAILS_VERBOSE environment variable when verbose is true" do
        env_value = nil
        allow(mock_task).to receive(:invoke) do
          env_value = ENV.fetch("REACT_ON_RAILS_VERBOSE", nil)
        end

        described_class.generate(verbose: true)

        expect(env_value).to eq("true")
        # Ensure cleanup happened
        expect(ENV.fetch("REACT_ON_RAILS_VERBOSE", nil)).to be_nil
      end

      it "sets REACT_ON_RAILS_VERBOSE environment variable to false when verbose is false" do
        env_value = nil
        allow(mock_task).to receive(:invoke) do
          env_value = ENV.fetch("REACT_ON_RAILS_VERBOSE", nil)
        end

        described_class.generate(verbose: false)

        expect(env_value).to eq("false")
        # Ensure cleanup happened
        expect(ENV.fetch("REACT_ON_RAILS_VERBOSE", nil)).to be_nil
      end

      it "cleans up REACT_ON_RAILS_VERBOSE environment variable even when task fails" do
        allow(mock_task).to receive(:invoke).and_raise(StandardError.new("Task failed"))

        # Mock STDERR.puts to suppress error output
        # rubocop:disable Style/GlobalStdStream
        allow(STDERR).to receive(:puts)
        # rubocop:enable Style/GlobalStdStream

        expect { described_class.generate(verbose: true) }.to raise_error(SystemExit)

        # Ensure cleanup happened even on failure
        expect(ENV.fetch("REACT_ON_RAILS_VERBOSE", nil)).to be_nil
      end
    end

    context "when not in Bundler context" do
      before do
        # Ensure we're not in Bundler context
        hide_const("Bundler") if defined?(Bundler)
      end

      it "runs pack generation successfully in verbose mode using bundle exec" do
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process

        expect(described_class).to have_received(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
      end

      it "runs pack generation successfully in quiet mode using bundle exec" do
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "false" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs",
                out: File::NULL, err: File::NULL)
          .and_return(true)

        expect { described_class.generate(verbose: false) }
          .to output(/📦 Generating packs\.\.\. ✅/).to_stdout_from_any_process

        expect(described_class).to have_received(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "false" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs",
                out: File::NULL, err: File::NULL)
      end

      it "exits with error when pack generation fails" do
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "false" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs",
                out: File::NULL, err: File::NULL)
          .and_return(false)

        expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
      end
    end

    context "when Rails is not available" do
      before do
        stub_const("Bundler", Module.new)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return("/path/to/Gemfile")

        # Rails not available
        hide_const("Rails") if defined?(Rails)
      end

      it "falls back to bundle exec when Rails is not defined" do
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process

        expect(described_class).to have_received(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
      end
    end

    context "when calling bundle exec from within Bundler context" do
      before do
        # Ensure we're not in Rails context to trigger bundle exec path
        hide_const("Rails") if defined?(Rails)
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_configured?).and_return(false)
      end

      it "unwraps the Bundler context before executing with with_unbundled_env" do
        bundler_module = Module.new do
          def self.respond_to?(method, *)
            method == :with_unbundled_env
          end

          def self.with_unbundled_env
            yield
          end
        end
        stub_const("Bundler", bundler_module)

        allow(bundler_module).to receive(:with_unbundled_env).and_yield
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        described_class.generate(verbose: true)

        expect(bundler_module).to have_received(:with_unbundled_env)
      end

      it "falls back to with_clean_env when with_unbundled_env is not available" do
        bundler_module = Module.new do
          def self.respond_to?(method, *)
            method == :with_clean_env
          end

          def self.with_clean_env
            yield
          end
        end
        stub_const("Bundler", bundler_module)

        allow(bundler_module).to receive(:with_clean_env).and_yield
        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        described_class.generate(verbose: true)

        expect(bundler_module).to have_received(:with_clean_env)
      end

      it "executes directly when neither with_unbundled_env nor with_clean_env are available" do
        bundler_module = Module.new do
          def self.respond_to?(_method, *)
            false
          end
        end
        stub_const("Bundler", bundler_module)

        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process

        expect(described_class).to have_received(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
      end

      it "executes directly when Bundler is not defined" do
        hide_const("Bundler") if defined?(Bundler)

        allow(described_class).to receive(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
          .and_return(true)

        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process

        expect(described_class).to have_received(:system)
          .with({ "REACT_ON_RAILS_VERBOSE" => "true" },
                "bundle", "exec", "rake", "react_on_rails:generate_packs")
      end
    end
  end

  # Regression coverage for https://github.com/shakacode/react_on_rails/issues/5297:
  # bin/dev may set variables after Bundler loads, and the unbundled pack-generation
  # child must still see them.
  describe "environment passed to the bundle exec child" do
    let(:probe_key) { "ROR_PACK_GENERATOR_SPEC_PROBE" }

    around do |example|
      original_value = ENV.fetch(probe_key, nil)
      example.run
    ensure
      original_value.nil? ? ENV.delete(probe_key) : ENV[probe_key] = original_value
    end

    # Runs the real child inside the real Bundler.with_unbundled_env and reports what it saw.
    def child_view_of(key, gemfile_key: "BUNDLE_GEMFILE")
      seen = nil
      allow(described_class).to receive(:system) do |env, *_command, **_options|
        script = "puts [ENV[#{key.inspect}].inspect, ENV[#{gemfile_key.inspect}].inspect].join(' ')"
        seen = IO.popen(env, [RbConfig.ruby, "-e", script], &:read).split
        true
      end
      described_class.send(:run_via_bundle_exec, silent: true)
      seen
    end

    it "passes a variable set after Bundler loads" do
      ENV[probe_key] = "after"

      expect(child_view_of(probe_key)).to eq(['"after"', "nil"])
    end

    it "keeps a variable set before Bundler loads without passing it again" do
      ENV[probe_key] = "before"
      allow(Bundler).to receive(:original_env).and_wrap_original do |original|
        original.call.merge(probe_key => "before")
      end

      expect(described_class.send(:runtime_env_changes)).not_to have_key(probe_key)
      expect(child_view_of(probe_key)).to eq(['"before"', "nil"])
    end

    it "unsets a variable deleted after Bundler loads" do
      ENV.delete(probe_key)
      allow(Bundler).to receive(:original_env).and_wrap_original do |original|
        original.call.merge(probe_key => "stale")
      end

      expect(described_class.send(:runtime_env_changes)).to include(probe_key => nil)
      expect(child_view_of(probe_key)).to eq(%w[nil nil])
    end

    it "leaves out the variables Bundler manages" do
      changes = described_class.send(:runtime_env_changes)

      expect(changes.keys.grep(/\ABUNDLER?_/)).to be_empty
      expect(changes.keys & described_class::BUNDLER_MANAGED_ENV_KEYS).to be_empty
    end

    # Mirrors the three rows of the issue's table with real Ruby processes: plain `ruby`
    # with the assignment after or before `require "bundler/setup"`, and `bundle exec`.
    describe "from a bin/dev-like script" do
      let(:gem_root) { File.expand_path("../../..", __dir__) }

      def run_script(order, bundle_exec:)
        Dir.mktmpdir do |dir|
          script = File.join(dir, "bin_dev_probe.rb")
          File.write(script, <<~RUBY)
            ENV[#{probe_key.inspect}] ||= "true" if #{order.inspect} == "before"
            require "bundler/setup"
            ENV[#{probe_key.inspect}] ||= "true" if #{order.inspect} == "after"
            require "react_on_rails/dev/pack_generator"

            generator = ReactOnRails::Dev::PackGenerator
            generator.define_singleton_method(:system) do |env, *_command, **_options|
              Kernel.system(env, RbConfig.ruby, "-e",
                            "exit(ENV['#{probe_key}'] == 'true' && ENV['BUNDLE_GEMFILE'].nil?)")
            end
            exit(generator.send(:run_via_bundle_exec, silent: true) ? 0 : 1)
          RUBY

          command = bundle_exec ? ["bundle", "exec", RbConfig.ruby, script] : [RbConfig.ruby, script]
          env = { "BUNDLE_GEMFILE" => Bundler.default_gemfile.to_s, probe_key => nil }
          Bundler.with_unbundled_env { system(env, *command, chdir: gem_root, out: File::NULL) }
        end
      end

      it "passes the variable when bin/dev sets it after requiring bundler/setup" do
        expect(run_script("after", bundle_exec: false)).to be(true)
      end

      it "passes the variable when bin/dev sets it before requiring bundler/setup" do
        expect(run_script("before", bundle_exec: false)).to be(true)
      end

      it "passes the variable under bundle exec bin/dev in either order" do
        expect(run_script("after", bundle_exec: true)).to be(true)
        expect(run_script("before", bundle_exec: true)).to be(true)
      end
    end
  end
end
