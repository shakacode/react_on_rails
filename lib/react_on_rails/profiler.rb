module ReactOnRails
  class Profiler
    def initialize(component_name:)
      @component_name = component_name
      @profile_id = SecureRandom.uuid
    end

    def self.enabled?
      ENV["REACT_ON_RAILS_PROFILER"] == "true"
    end

    def start
      return unless self.class.enabled?

      @start_time = Time.now
    end

    def profile(operation)
      return yield unless self.class.enabled?

      result = nil
      duration = Benchmark.realtime do
        result = yield
      end
      Rails.logger.info { "[react_on_rails] #{@component_name} #{@profile_id} #{operation.parameterize}: #{duration * 1000}ms" }
      result
    end
  end
end