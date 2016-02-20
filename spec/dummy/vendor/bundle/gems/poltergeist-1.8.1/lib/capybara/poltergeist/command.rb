require 'securerandom'

module Capybara::Poltergeist
  class Command
    attr_reader :id

    def initialize(name, *args)
      @id = SecureRandom.uuid
      @name = name
      @args = args
    end

    def message
      JSON.dump({ 'id' => @id, 'name' => @name, 'args' => @args })
    end
  end
end