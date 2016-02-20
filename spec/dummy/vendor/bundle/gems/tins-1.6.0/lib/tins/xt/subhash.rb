require 'tins/subhash'

module Tins
  class ::Hash
    include Tins::Subhash

    def subhash!(*patterns)
      replace subhash(*patterns)
    end
  end
end
