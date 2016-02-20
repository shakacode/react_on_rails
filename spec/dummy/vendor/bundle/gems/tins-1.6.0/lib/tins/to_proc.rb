module Tins
  module ToProc
    # :nocov:
    def to_proc
      lambda do |obj, *args|
        obj.__send__(self, *args[0..-1])
      end
    end
  end
end

require 'tins/alias'
