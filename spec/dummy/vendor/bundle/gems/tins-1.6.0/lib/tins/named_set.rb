require 'set'

module Tins
  class NamedSet < Set
    def initialize(name)
      @name = name
      super()
    end

    attr_accessor :name
  end
end
