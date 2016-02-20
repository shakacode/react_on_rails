module Capybara::Poltergeist::NetworkTraffic
  class Error
    def initialize(data)
      @data = data
    end

    def url
      @data['url']
    end

    def code
      @data['errorCode']
    end

    def description
      @data['errorString']
    end
  end
end
