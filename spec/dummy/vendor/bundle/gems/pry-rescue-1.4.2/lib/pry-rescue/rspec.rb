require 'pry-rescue'
require 'rspec'

class PryRescue
  class RSpec

    # Run an Rspec example within Pry::rescue{ }.
    #
    # Takes care to ensure that `try-again` will work.
    def self.run(example)
      Pry::rescue do
        begin
          before

          example.binding.eval('@exception = nil; @example && @example.instance_variable_set(:@exception, nil)')
          example.binding.eval('example.instance_variable_set(:@exception, nil) if defined?(example)')
          example.binding.eval('@example && @example.example_group_instance.instance_variable_set(:@__memoized, {})')
          example.binding.eval('example.example_group_instance.instance_variable_set(:@__memoized, {}) if defined?(example)')
          example.run
          e = example.binding.eval('@exception || @example && @example.instance_variable_get(:@exception)')
          e ||= example.binding.eval('example.instance_variable_get(:@exception) if defined?(example)')
          if e
            Pry::rescued(e)
          end

        ensure
          after
        end
      end
    end

    def self.before
      monkeypatch_capybara if defined?(Capybara)
    end

    def self.after
      after_filters.each(&:call)
    end

    # Shunt Capybara's after filter from before Pry::rescued to after.
    #
    # The after filter navigates to 'about:blank', but people debugging
    # tests probably want to see the page that failed.
    def self.monkeypatch_capybara
      unless Capybara.respond_to?(:reset_sessions_after_rescue!)
        class << Capybara
          alias_method :reset_sessions_after_rescue!, :reset_sessions!
          def reset_sessions!; end
        end

        after_filters << Capybara.method(:reset_sessions_after_rescue!)
      end
    end

    def self.after_filters
      @after_filters ||= []
    end
  end
end

RSpec.configure do |c|
  c.around(:each) do |example|
    PryRescue::RSpec.run example
  end
end
