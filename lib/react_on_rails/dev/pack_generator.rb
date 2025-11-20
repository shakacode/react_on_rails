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
            success = run_pack_generation
          else
            print "📦 Generating packs... "
            success = run_pack_generation(silent: true)
            puts success ? "✅" : "❌"
          end

          return if success

          puts "❌ Pack generation failed"
          exit 1
        end

        private

        def run_pack_generation(silent: false)
          # If we're already inside a Bundler context AND Rails is available (e.g., called from bin/dev),
          # we can directly require and run the task. Otherwise, use bundle exec.
          if should_run_directly?
            run_rake_task_directly(silent: silent)
          else
            run_via_bundle_exec(silent: silent)
          end
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

        def run_via_bundle_exec(silent: false)
          if silent
            system(
              "bundle", "exec", "rake", "react_on_rails:generate_packs",
              out: File::NULL, err: File::NULL
            )
          else
            system("bundle", "exec", "rake", "react_on_rails:generate_packs")
          end
        end
      end
    end
  end
end
