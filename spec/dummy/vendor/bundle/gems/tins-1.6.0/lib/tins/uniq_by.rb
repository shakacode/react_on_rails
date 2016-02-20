module Tins
  module UniqBy
    def uniq_by(&b)
      b ||= lambda { |x| x }
      inject({}) { |h, e| h[b[e]] ||= e; h }.values
    end
  end
end

require 'tins/alias'
