module Tins
  module IfPredicate
    def if?
      self ? self : nil
    end
  end
end
