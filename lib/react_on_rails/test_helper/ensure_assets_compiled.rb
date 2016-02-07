module ReactOnRails
  module TestHelper
    class EnsureAssetsCompiled
      class << self
        attr_accessor :has_been_run
        @has_been_run = false
      end

      attr_reader :webpack_assets_status_checker,
                  :webpack_assets_compiler,
                  :webpack_process_checker

      MAX_TIME_TO_WAIT = 5

      def initialize(webpack_assets_status_checker: nil,
                     webpack_assets_compiler: nil,
                     webpack_process_checker: nil)
        @webpack_assets_status_checker = webpack_assets_status_checker
        @webpack_assets_compiler = webpack_assets_compiler
        @webpack_process_checker = webpack_process_checker
      end

      def call
        return if self.class.has_been_run

        loop_count = 0
        loop do
          break if webpack_assets_status_checker.up_to_date?

          puts_first_iteration_message(loop_count)

          if webpack_process_checker.running? && loop_count < MAX_TIME_TO_WAIT
            loop_count += 1
            sleep 1
          else
            puts_max_iterations_message(loop_count)

            webpack_assets_compiler.compile
            puts
            break
          end
        end

        self.class.has_been_run = true
      end

      def puts_first_iteration_message(loop_count)
        return unless loop_count == 0

        puts "\n\nReact on Rails is ensuring your JavaScript generated files are up to date!"
      end

      def puts_max_iterations_message(loop_count)
        if loop_count == MAX_TIME_TO_WAIT
          stale_files = webpack_assets_status_checker.whats_not_up_to_date.join("\n")

          puts <<-MSG

Even though we detected the webpack watch processes are running, we found files modified that are
not causing a rebuild of your generated files:

#{stale_files}

One possibility is that you modified a file in your directory that is not a dependency of
your webpack files: #{webpack_assets_status_checker.client_dir}

To be sure, we will now rebuild your generated files.
          MSG
        end
      end
    end
  end
end
