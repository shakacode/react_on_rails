module ReactOnRails
  class JsonParseError < ::ReactOnRails::Error
    attr_reader :json

    def initialize(parse_error, json)
      @json = json
      @original_error = parse_error
      super(parse_error.message)
    end

    def to_honeybadger_context
      to_error_context
    end

    def raven_context
      to_error_context
    end

    def to_error_context
      {
        original_error: @original_error,
        json: @json
      }
    end
  end
end
