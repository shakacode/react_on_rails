require 'tins/count_by'

module Tins
  module ::Enumerable
    include CountBy
  end

  class ::Array
    include CountBy
  end
end
