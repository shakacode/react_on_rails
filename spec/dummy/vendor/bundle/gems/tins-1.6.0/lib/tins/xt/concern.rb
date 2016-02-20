require 'tins/concern'

module Tins
  module Concern
    module ModuleMixin
      def tins_concern_configure(*args)
        Thread.current[:tin_concern_args] = args
        self
      end

      def tins_concern_args
        Thread.current[:tin_concern_args]
      end
    end
  end

  class ::Module
    include Tins::Concern::ModuleMixin
  end
end
