module Tins
  module RangePlus
    def +(other)
      to_a + other.to_a
    end
  end
end

require 'tins/alias'
