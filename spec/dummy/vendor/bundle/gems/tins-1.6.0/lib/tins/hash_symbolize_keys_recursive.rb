module Tins
  module HashSymbolizeKeysRecursive
    def symbolize_keys_recursive
      inject(self.class.new) do |h,(k, v)|
        k = k.to_s
        k.empty? and next
        case v
        when Hash
          h[k.to_sym] = v.symbolize_keys_recursive
        when Array
          h[k.to_sym] = a = v.dup
          v.each_with_index do |x, i|
            Hash === x and a[i] = x.symbolize_keys_recursive
          end
        else
          h[k.to_sym] = v
        end
        h
      end
    end

    def symbolize_keys_recursive!
      replace symbolize_keys_recursive
    end
  end
end

require 'tins/alias'
