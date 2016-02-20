module Capybara::Poltergeist
  module JSON
    def self.load(message)
      if dumpy_multi_json?
        MultiJson.load(message)
      else
        MultiJson.decode(message)
      end
    end

    def self.dump(message)
      if dumpy_multi_json?
        MultiJson.dump(message)
      else
        MultiJson.encode(message)
      end
    end

    private

    def self.dumpy_multi_json?
      MultiJson.respond_to?(:dump) && MultiJson.respond_to?(:load)
    end
  end
end
