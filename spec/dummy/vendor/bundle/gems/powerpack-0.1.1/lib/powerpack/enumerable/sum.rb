unless Enumerable.method_defined? :sum
  module Enumerable
    # Sums up elements of a collection by invoking their `+` method.
    # Most useful for summing up numbers.
    #
    # @param default [Object] an optional default return value if there are no elements.
    #   It's nil by default.
    # @return The sum of the elements or the default value if there are no
    #   elements.
    #
    # @example
    #   [1, 2, 3].sum #=> 6
    #   ["a", "b", "c"].sum #=> "abc"
    #   [[1], [2], [3]].sum #=> [1, 2, 3]
    #   [].sum #=> nil
    #   [].sum(0) #=> 0
    def sum(default = nil)
      reduce(&:+) || default
    end
  end
end
