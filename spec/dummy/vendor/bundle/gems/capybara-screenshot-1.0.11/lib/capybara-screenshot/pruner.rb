module Capybara
  module Screenshot
    class Pruner
      attr_reader :strategy

      def initialize(strategy)
        @strategy = strategy

        @strategy_proc = case strategy
        when :keep_all
          lambda { }
        when :keep_last_run
          lambda { prune_with_last_run_strategy }
        when Hash
          raise ArgumentError, ":keep key is required" unless strategy[:keep]
          raise ArgumentError, ":keep value must be number greater than zero" unless strategy[:keep].to_i > 0
          lambda { prune_with_numeric_strategy(strategy[:keep].to_i) }
        else
          fail "Invalid prune strategy #{strategy}. `:keep_all`or `{ keep: 10 }` are valid examples."
        end
      end

      def prune_old_screenshots
        strategy_proc.call
      end

      private
      attr_reader :strategy_proc

      def wildcard_path
        File.expand_path('*.{html,png}', Screenshot.capybara_root)
      end

      def prune_with_last_run_strategy
        FileUtils.rm_rf(Dir.glob(wildcard_path))
      end

      def prune_with_numeric_strategy(count)
        files = Dir.glob(wildcard_path).sort_by do |file_name|
          File.mtime(File.expand_path(file_name, Screenshot.capybara_root))
        end

        FileUtils.rm_rf(files[0...-count])
      end
    end
  end
end
