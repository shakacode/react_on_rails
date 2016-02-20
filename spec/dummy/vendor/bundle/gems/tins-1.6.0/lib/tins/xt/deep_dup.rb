require 'tins/deep_dup'

module Tins
  class ::Object
    include Tins::DeepDup
  end
end
