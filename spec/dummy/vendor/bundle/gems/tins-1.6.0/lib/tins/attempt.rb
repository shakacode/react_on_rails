module Tins
  module Attempt
    def attempt(opts = {}, &block)
      sleep           = nil
      exception_class = StandardError
      if Numeric === opts
        attempts = opts
      else
        attempts        = opts[:attempts] || 1
        exception_class = opts[:exception_class] if opts.key?(:exception_class)
        sleep           = opts[:sleep]
        reraise         = opts[:reraise]
      end
      return if attempts <= 0
      count = 0
      if exception_class.nil?
        begin
          count += 1
          if block.call(count)
            return true
          elsif count < attempts
            sleep_duration(sleep, count)
          end
        end until count == attempts
        false
      else
        begin
          count += 1
          block.call(count)
          true
        rescue exception_class
          if count < attempts
            sleep_duration(sleep, count)
            retry
          end
          reraise ? raise : false
        end
      end
    end

    private

    def sleep_duration(duration, count)
      case duration
      when Numeric
        sleep duration
      when Proc
        sleep duration.call(count)
      end
    end
  end
end
