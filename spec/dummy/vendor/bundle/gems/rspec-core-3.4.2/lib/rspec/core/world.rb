module RSpec
  module Core
    # @api private
    #
    # Internal container for global non-configuration data.
    class World
      # @private
      attr_reader :example_groups, :filtered_examples

      # Used internally to determine what to do when a SIGINT is received.
      attr_accessor :wants_to_quit

      def initialize(configuration=RSpec.configuration)
        @configuration = configuration
        @example_groups = []
        @example_group_counts_by_spec_file = Hash.new(0)
        @filtered_examples = Hash.new do |hash, group|
          hash[group] = filter_manager.prune(group.examples)
        end
      end

      # @api private
      #
      # Apply ordering strategy from configuration to example groups.
      def ordered_example_groups
        ordering_strategy = @configuration.ordering_registry.fetch(:global)
        ordering_strategy.order(@example_groups)
      end

      # @api private
      #
      # Reset world to 'scratch' before running suite.
      def reset
        example_groups.clear
        @shared_example_group_registry = nil
      end

      # @private
      def filter_manager
        @configuration.filter_manager
      end

      # @private
      def registered_example_group_files
        @example_group_counts_by_spec_file.keys
      end

      # @api private
      #
      # Register an example group.
      def register(example_group)
        @configuration.on_example_group_definition_callbacks.each { |block| block.call(example_group) }
        example_groups << example_group
        @example_group_counts_by_spec_file[example_group.metadata[:absolute_file_path]] += 1
        example_group
      end

      # @private
      def num_example_groups_defined_in(file)
        @example_group_counts_by_spec_file[file]
      end

      # @private
      def shared_example_group_registry
        @shared_example_group_registry ||= SharedExampleGroup::Registry.new
      end

      # @private
      def inclusion_filter
        @configuration.inclusion_filter
      end

      # @private
      def exclusion_filter
        @configuration.exclusion_filter
      end

      # @api private
      #
      # Get count of examples to be run.
      def example_count(groups=example_groups)
        FlatMap.flat_map(groups) { |g| g.descendants }.
          inject(0) { |a, e| a + e.filtered_examples.size }
      end

      # @private
      def all_example_groups
        FlatMap.flat_map(example_groups) { |g| g.descendants }
      end

      # @private
      def all_examples
        FlatMap.flat_map(all_example_groups) { |g| g.examples }
      end

      # @api private
      #
      # Find line number of previous declaration.
      def preceding_declaration_line(filter_line)
        declaration_line_numbers.sort.inject(nil) do |highest_prior_declaration_line, line|
          line <= filter_line ? line : highest_prior_declaration_line
        end
      end

      # @private
      def reporter
        @configuration.reporter
      end

      # @private
      def source_cache
        @source_cache ||= begin
          RSpec::Support.require_rspec_core "source"
          Source::Cache.new(@configuration)
        end
      end

      # @api private
      #
      # Notify reporter of filters.
      def announce_filters
        fail_if_config_and_cli_options_invalid
        filter_announcements = []

        announce_inclusion_filter filter_announcements
        announce_exclusion_filter filter_announcements

        unless filter_manager.empty?
          if filter_announcements.length == 1
            report_filter_message("Run options: #{filter_announcements[0]}")
          else
            report_filter_message("Run options:\n  #{filter_announcements.join("\n  ")}")
          end
        end

        if @configuration.run_all_when_everything_filtered? && example_count.zero? && !@configuration.only_failures?
          report_filter_message("#{everything_filtered_message}; ignoring #{inclusion_filter.description}")
          filtered_examples.clear
          inclusion_filter.clear
        end

        return unless example_count.zero?

        example_groups.clear
        if filter_manager.empty?
          report_filter_message("No examples found.")
        elsif exclusion_filter.empty? || inclusion_filter.empty?
          report_filter_message(everything_filtered_message)
        end
      end

      # @private
      def report_filter_message(message)
        reporter.message(message) unless @configuration.silence_filter_announcements?
      end

      # @private
      def everything_filtered_message
        "\nAll examples were filtered out"
      end

      # @api private
      #
      # Add inclusion filters to announcement message.
      def announce_inclusion_filter(announcements)
        return if inclusion_filter.empty?

        announcements << "include #{inclusion_filter.description}"
      end

      # @api private
      #
      # Add exclusion filters to announcement message.
      def announce_exclusion_filter(announcements)
        return if exclusion_filter.empty?

        announcements << "exclude #{exclusion_filter.description}"
      end

    private

      def declaration_line_numbers
        @declaration_line_numbers ||= FlatMap.flat_map(example_groups, &:declaration_line_numbers)
      end

      def fail_if_config_and_cli_options_invalid
        return unless @configuration.only_failures_but_not_configured?

        reporter.abort_with(
          "\nTo use `--only-failures`, you must first set " \
          "`config.example_status_persistence_file_path`.",
          1 # exit code
        )
      end
    end
  end
end
