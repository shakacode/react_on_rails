module Capybara::Poltergeist::NetworkTraffic
  class Response
    def initialize(data)
      @data = data
    end

    def url
      @data['url']
    end

    def status
      @data['status']
    end

    def status_text
      @data['statusText']
    end

    def headers
      @data['headers']
    end

    def redirect_url
      @data['redirectURL']
    end

    def body_size
      @data['bodySize']
    end

    def content_type
      @data['contentType']
    end

    def time
      @data['time'] && Time.parse(@data['time'])
    end
  end
end

