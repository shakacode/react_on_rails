module Tins
  module DeepDup
    def deep_dup
      Marshal.load(Marshal.dump(self))
    rescue TypeError
      return self
    end
  end
end

require 'tins/alias'
