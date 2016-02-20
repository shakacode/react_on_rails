require 'tins/method_description'

module Tins
  class ::UnboundMethod
    include MethodDescription

    alias to_s description

    def inspect
      "#<#{self.class}: #{description}>"
    end
  end

  class ::Method
    include MethodDescription

    alias to_s description

    def inspect
      "#<#{self.class}: #{description}>"
    end
  end
end
