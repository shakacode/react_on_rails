module Tins
  # This module can be mixed into all classes, whose instances respond to the
  # [] and size-methods, like for example Array. The returned elements from []
  # should respond to the succ method.
  module Minimize
    # Returns a minimized version of this object, that is successive elements
    # are substituted with ranges a..b. In the situation ..., x, y,... and y !=
    # x.succ a range x..x is created, to make it easier to iterate over all the
    # ranges in one run. A small example:
    #  [ 'A', 'B', 'C', 'G', 'K', 'L', 'M' ].minimize # => [ 'A'..'C', 'G'..'G', 'K'..'M' ]
    #
    # If the order of the original elements doesn't matter, it's a good idea to
    # first sort them and then minimize:
    #  [ 5, 1, 4, 2 ].sort.minimize # => [ 1..2, 4..5 ]
    def minimize
      result = []
      last_index = size - 1
      size.times do |i|
        result << [ self[0] ] if i == 0
        if self[i].succ != self[i + 1] or i == last_index
          result[-1] << self[i]
          result << [ self[i + 1] ] unless i == last_index
        end
      end
      result.map! { |a, b| a..b }
    end

    # First minimizes this object, then calls the replace method with the
    # result.
    def minimize!
      replace minimize
    end

    # Invert a minimized version of an object. Some small examples:
    #  [ 'A'..'C', 'G'..'G', 'K'..'M' ].unminimize # => [ 'A', 'B', 'C', 'G', 'K', 'L', 'M' ]
    # and
    #  [ 1..2, 4..5 ].unminimize # => [ 1, 2, 4, 5 ]
    def unminimize
      result = []
      for range in self
        for e in range
          result << e
        end
      end
      result
    end

    # Invert a minimized version of this object in place.
    def unminimize!
      replace unminimize
    end
  end
end

require 'tins/alias'
