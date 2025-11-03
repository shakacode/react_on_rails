# frozen_string_literal: true

require "English"

module ReactOnRails
  module Dev
    class PackGenerator
      class << self
        def generate(verbose: false)
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
          # If we're already inside a Bundler context (e.g., called from bin/dev),
          # we can directly require and run the task. Otherwise, use bundle exec.
          if defined?(Bundler)
            run_rake_task_directly(silent: silent)
          else
            run_via_bundle_exec(silent: silent)
          end
        end

        def run_rake_task_directly(silent: false)
          require "rake"

          # Load Rails environment if not already loaded
          require File.expand_path("config/environment", Dir.pwd) unless defined?(Rails)

          Rake::Task.clear
          Rails.application.load_tasks unless Rake::Task.task_defined?("react_on_rails:generate_packs")

          if silent
            original_stdout = $stdout
            original_stderr = $stderr
            $stdout = StringIO.new
            $stderr = StringIO.new
          end

          begin
            Rake::Task["react_on_rails:generate_packs"].invoke
            true
          rescue StandardError => e
            warn "Error generating packs: #{e.message}" unless silent
            false
          ensure
            if silent
              $stdout = original_stdout
              $stderr = original_stderr
            end
          end
        end

        def run_via_bundle_exec(silent: false)
          if silent
            system "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
          else
            system "bundle exec rake react_on_rails:generate_packs"
          end
        end
      end
    end
  end
end
