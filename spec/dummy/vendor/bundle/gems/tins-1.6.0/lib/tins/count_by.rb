module Tins
  module CountBy
    def count_by(&b)
      b ||= lambda { |x| true }
      inject(0) { |s, e| s += 1 if b[e]; s }
    end
  end
end
