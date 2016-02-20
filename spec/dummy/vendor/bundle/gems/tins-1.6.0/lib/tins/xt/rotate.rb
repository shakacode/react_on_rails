module Tins
  class ::Array
    unless method_defined?(:rotate)
      include Tins::Rotate
    end
  end
end
