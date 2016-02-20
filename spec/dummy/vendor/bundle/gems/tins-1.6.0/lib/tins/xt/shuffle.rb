require 'tins/shuffle'

module Tins
  class ::Array
    if method_defined?(:shuffle)
      warn "#{self}#shuffle already defined, didn't include at #{__FILE__}:#{__LINE__}"
    else
      include Shuffle
    end
  end
end
