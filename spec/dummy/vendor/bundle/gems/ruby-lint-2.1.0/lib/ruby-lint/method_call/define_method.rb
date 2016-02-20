module RubyLint
  module MethodCall
    ##
    # The DefineMethod class is used to process `define_method` calls.
    # Currently this class is only used to set the instance type of the block
    # to the correct value.
    #
    class DefineMethod < Base
      ##
      # @see Base#evaluate
      #
      def evaluate(arguments, context, block = nil)
        block.instance! if block && block.block?
      end
    end # DefineMethod
  end # MethodCall
end # RubyLint
