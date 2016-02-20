module Tins
  module Shuffle
    # :nocov:
    def shuffle!
      (size - 1) .downto(1) do |i|
        j = rand(i + 1)
        self[i], self[j] = self[j], self[i]
      end
      self
    end

    def shuffle
      dup.shuffle!
    end
  end
end

require 'tins/alias'
