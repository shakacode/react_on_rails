module Tins
  class Bijection < Hash
    def self.[](*pairs)
      pairs.size % 2 == 0 or
        raise ArgumentError, "odd number of arguments for #{self}"
      new.fill do |obj|
        (pairs.size / 2).times do |i|
          j = 2 * i
          key = pairs[j]
          value = pairs[j + 1]
          obj.key?(key) and raise ArgumentError, "duplicate key #{key.inspect} for #{self}"
          obj.inverted.key?(value) and raise ArgumentError, "duplicate value #{value.inspect} for #{self}"
          obj[pairs[j]] = pairs[j + 1]
        end
      end
    end

    def initialize(inverted = Bijection.new(self))
      @inverted = inverted
    end

    def fill
      if empty?
        yield self
        freeze
      end
      self
    end

    def freeze
      r = super
      unless @inverted.frozen?
        @inverted.freeze
      end
      r
    end

    def []=(key, value)
      key?(key) and return
      super
      @inverted[value] = key
    end

    attr_reader :inverted
  end
end
