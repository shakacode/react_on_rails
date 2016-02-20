module RubyLint
  module MethodCall
    ##
    # The Include class is used for evaluating the use of `include` and
    # `extend` method calls.
    #
    class Include < Base
      ##
      # Hash containing the source and target definition types for both
      # `include` and `extend` method calls.
      #
      COPY_TYPES = {
        :include => {
          :const           => :const,
          :instance_method => :instance_method
        },
        :extend => {
          :const           => :const,
          :instance_method => :method
        }
      }

      ##
      # @see Base#evaluate
      #
      def evaluate(arguments, context, block = nil)
        node_name = node.children[1]

        arguments.each do |source|
          COPY_TYPES[node_name].each do |from, to|
            source.list(from).each do |definition|
              context.add(to, definition.name, definition)
            end
          end
        end
      end
    end # Include
  end # MethodCall
end # RubyLint
