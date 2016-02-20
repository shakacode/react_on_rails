module Tins
  module CasePredicate
    def case?(*args)
      args.find { |a| a === self }
    end
  end
end
