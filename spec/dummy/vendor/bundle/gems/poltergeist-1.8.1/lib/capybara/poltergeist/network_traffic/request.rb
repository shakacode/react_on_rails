module Capybara::Poltergeist::NetworkTraffic
  class Request
    attr_reader :response_parts, :error

    def initialize(data, response_parts = [], error = nil)
      @data           = data
      @response_parts = response_parts
      @error = error
    end

    def url
      @data['url']
    end

    def method
      @data['method']
    end

    def headers
      @data['headers']
    end

    def time
      @data['time'] && Time.parse(@data['time'])
    end
  end
end
