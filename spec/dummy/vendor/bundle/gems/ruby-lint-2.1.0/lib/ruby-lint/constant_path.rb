module RubyLint
  ##
  # The ConstantPath class can be used for various operations on a constant AST
  # node such as generating the full constant name.
  #
  # @!attribute [r] node
  #  @return [RubyLint::AST::Node]
  #
  class ConstantPath
    attr_reader :node

    ##
    # Hash containing node types to remap when resolving them.
    #
    # @return [Hash]
    #
    REMAP_TYPES = {
      :casgn => :const
    }

    ##
    # @param [RubyLint::AST::Node] node
    #
    def initialize(node)
      @node = node
    end

    ##
    # Retrieves the definition associated with the constant path and returns
    # it, or `nil` if no definition was found.
    #
    # @param [RubyLint::Definition::RubyObject] scope The scope to use for the
    #  lookups.
    # @return [RubyLint::Definition::RubyObject]
    #
    def resolve(scope)
      current = scope

      constant_segments.each_with_index do |(type, name), index|
        type  = REMAP_TYPES.fetch(type, type)
        found = current.lookup(type, name, index == 0)

        if found and found.const?
          current = found

        # Local variables and the likes.
        elsif found and found.value
          current = found.value

        else
          return
        end
      end

      return current
    end

    ##
    # Returns the very first segment of the constant path as an AST node.
    #
    # @return [RubyLint::AST::Node]
    #
    def root_node
      return constant_segments.first
    end

    ##
    # Returns a String containing the full constant path, e.g.
    # "RubyLint::Runner".
    #
    # @return [String]
    #
    def to_s
      return constant_segments.map { |seg| seg[1] }.join('::')
    end

    ##
    # Returns an Array containing the segments of a constant path.
    #
    # @param [RubyLint::AST::Node] node
    # @return [Array<String>]
    #
    def constant_segments(node = self.node)
      segments = []

      if has_child_node?(node)
        segments.concat(constant_segments(node.children[0]))
      end

      segments << [node.type, name_for_node(node)]

      return segments
    end

    private

    ##
    # @param [RubyLint::AST::Node] node
    # @return [TrueClass|FalseClass]
    #
    def has_child_node?(node)
      return node.children[0] && node.children[0].is_a?(AST::Node)
    end

    ##
    # @param [RubyLint::AST::Node] node
    # @return [String]
    #
    def name_for_node(node)
      if node.type == :casgn
        return node.children[1].to_s
      else
        return node.name
      end
    end
  end # ConstantPath
end # RubyLint
