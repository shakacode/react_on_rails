# frozen_string_literal: true

require "English"
require "stringio"
require_relative "../packer_utils"

module ReactOnRails
  module Dev
    # PackGenerator triggers the generation of React on Rails packs
    #
    # Design decisions:
    # 1. Why trigger via Rake task instead of direct Ruby code?
    #    - The actual pack generation logic lives in lib/react_on_rails/packs_generator.rb
    #    - The rake task (lib/tasks/generate_packs.rake) provides a stable, documented interface
    #    - This allows the implementation to evolve without breaking bin/dev
    #    - Users can also run the task directly: `rake react_on_rails:generate_packs`
    #
    # 2. Why two execution strategies (direct vs bundle exec)?
    #    - Direct Rake execution: Faster when already in Bundler/Rails context (bin/dev)
    #    - Bundle exec fallback: Required when called outside Rails context
    #    - This optimization avoids subprocess overhead in the common case
    #
    # 3. Why is the class named "PackGenerator" when it delegates?
    #    - It's a semantic wrapper around pack generation for the dev workflow
    #    - Provides a clean API for bin/dev without exposing Rake internals
    #    - Handles hook detection, error handling, and output formatting
    class PackGenerator
      # Variables Bundler sets or rewrites when it loads, besides the BUNDLE_ and BUNDLER_
      # prefixes. These must not reach the unbundled child, or it would run inside the
      # parent's bundle again.
      BUNDLER_MANAGED_ENV_KEYS = %w[
        PATH MANPATH RUBYOPT RUBYLIB GEM_HOME GEM_PATH RB_USER_INSTALL RUBYGEMS_GEMDEPS
      ].freeze

      class << self
        def generate(verbose: false)
          # Skip if shakapacker has a precompile hook configured
          if ReactOnRails::PackerUtils.shakapacker_precompile_hook_configured?
            if verbose
              hook_value = ReactOnRails::PackerUtils.shakapacker_precompile_hook_value
              puts "⏭️  Skipping pack generation (handled by shakapacker precompile hook: #{hook_value})"
            end
            return
          end

          if verbose
            puts "📦 Generating React on Rails packs..."
            success = run_pack_generation(silent: false, verbose: true)
          else
            print "📦 Generating packs... "
            success = run_pack_generation(silent: true, verbose: false)
            puts success ? "✅" : "❌"
          end

          return if success

          puts "❌ Pack generation failed"
          unless verbose
            puts ""
            puts "💡 Run with #{Rainbow('--verbose').cyan.bold} flag for detailed output:"
            puts "   #{Rainbow('bin/dev --verbose').green.bold}"
          end
          exit 1
        end

        private

        def run_pack_generation(silent: false, verbose: false)
          # Set environment variable for child processes to respect verbose mode
          ENV["REACT_ON_RAILS_VERBOSE"] = verbose ? "true" : "false"

          # If we're already inside a Bundler context AND Rails is available (e.g., called from bin/dev),
          # we can directly require and run the task. Otherwise, use bundle exec.
          if should_run_directly?
            run_rake_task_directly(silent:)
          else
            run_via_bundle_exec(silent:, verbose:)
          end
        ensure
          # Clean up environment variable
          ENV.delete("REACT_ON_RAILS_VERBOSE")
        end

        def should_run_directly?
          # Check if we're in a meaningful Bundler context with BUNDLE_GEMFILE
          return false unless defined?(Bundler)
          return false unless ENV["BUNDLE_GEMFILE"]
          return false unless rails_available?

          true
        end

        def rails_available?
          return false unless defined?(Rails)
          return false unless Rails.respond_to?(:application)
          return false if Rails.application.nil?

          # Verify Rails app can actually load tasks
          begin
            Rails.application.respond_to?(:load_tasks)
          rescue StandardError
            false
          end
        end

        def run_rake_task_directly(silent: false)
          require "rake"

          load_rake_tasks
          task = prepare_rake_task

          capture_output(silent) do
            task.invoke
            true
          end
        rescue StandardError => e
          handle_rake_error(e, silent)
          false
        end

        def load_rake_tasks
          return if Rake::Task.task_defined?("react_on_rails:generate_packs")

          Rails.application.load_tasks
        end

        def prepare_rake_task
          task = Rake::Task["react_on_rails:generate_packs"]
          task.reenable # Allow re-execution if called multiple times
          task
        end

        def capture_output(silent)
          return yield unless silent

          original_stdout = $stdout
          original_stderr = $stderr
          output_buffer = StringIO.new
          $stdout = output_buffer
          $stderr = output_buffer

          begin
            yield
          ensure
            $stdout = original_stdout
            $stderr = original_stderr
          end
        end

        def handle_rake_error(error, _silent)
          error_msg = "Error generating packs: #{error.message}"
          error_msg += "\n#{error.backtrace.join("\n")}" if ENV["DEBUG"]

          # Always write to stderr, even in silent mode
          # Use STDERR constant instead of warn/$stderr to bypass capture_output redirection
          # rubocop:disable Style/StderrPuts, Style/GlobalStdStream
          STDERR.puts error_msg
          # rubocop:enable Style/StderrPuts, Style/GlobalStdStream
        end

        def run_via_bundle_exec(silent: false, verbose: false)
          # with_unbundled_env resets ENV to Bundler's pre-load snapshot, so pass along every
          # change made since Bundler loaded (e.g. `ENV["FOO"] ||= "1"` in bin/dev).
          # REACT_ON_RAILS_VERBOSE is already set in run_pack_generation; keep it explicit here.
          env = runtime_env_changes.merge("REACT_ON_RAILS_VERBOSE" => verbose ? "true" : "false")

          # Need to unbundle to prevent Bundler from intercepting our bundle exec call
          # when already running inside a Bundler context (e.g., from bin/dev)
          with_unbundled_context do
            if silent
              system(
                env,
                "bundle", "exec", "rake", "react_on_rails:generate_packs",
                out: File::NULL, err: File::NULL
              )
            else
              system(env, "bundle", "exec", "rake", "react_on_rails:generate_packs")
            end
          end
        end

        # Variables that differ from Bundler's pre-load snapshot, as a `system` env hash.
        # A variable deleted since then maps to nil so the child does not get it back.
        # Bundler's own variables stay out, so the child still runs unbundled.
        def runtime_env_changes
          return {} unless defined?(Bundler) && Bundler.respond_to?(:original_env)

          original = Bundler.original_env
          (ENV.keys | original.keys).each_with_object({}) do |key, changes|
            next if bundler_managed_env_key?(key)

            value = ENV.fetch(key, nil)
            changes[key] = value unless value == original[key]
          end
        end

        # Compare uppercased names: Windows treats them case-insensitively and stores PATH as `Path`.
        def bundler_managed_env_key?(key)
          name = key.upcase
          name.start_with?("BUNDLE_", "BUNDLER_") || BUNDLER_MANAGED_ENV_KEYS.include?(name)
        end

        # DRY helper method for Bundler context switching with API compatibility
        # Supports both new (with_unbundled_env) and legacy (with_clean_env) Bundler APIs
        def with_unbundled_context(&)
          if defined?(Bundler)
            if Bundler.respond_to?(:with_unbundled_env)
              Bundler.with_unbundled_env(&)
            elsif Bundler.respond_to?(:with_clean_env)
              Bundler.with_clean_env(&)
            else
              # Fallback if neither method is available (very old Bundler versions)
              yield
            end
          else
            yield
          end
        end
      end
    end
  end
end
