require 'tins/uniq_by'

module Tins
  module ::Enumerable
    include UniqBy
  end

  class ::Array
    include UniqBy

    def uniq_by!(&b)
      replace uniq_by(&b)
    end
  end
end
