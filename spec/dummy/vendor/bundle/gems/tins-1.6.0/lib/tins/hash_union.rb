module Tins
  module HashUnion
    def |(other)
      case
      when other.respond_to?(:to_hash)
        other = other.to_hash
      when other.respond_to?(:to_h)
        other = other.to_h
      end
      other.merge(self)
    end
  end
end

require 'tins/alias'
