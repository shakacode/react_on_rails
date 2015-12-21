module GeneratorErrors
  class << self
    def output
      @output ||= []
    end

    def add_error(message)
      output << message
    end

    def errors
      output
    end
  end
end
