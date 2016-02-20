module RubyLint
  ##
  # {RubyLint::NestedStack} is a basic implementation of a nested stack. It's
  # primarily used by {RubyLint::VirtualMachine} for storing variables and
  # values during assignments.
  #
  class NestedStack
    def initialize
      @values = []
    end

    ##
    # Adds a new stack to push values to.
    #
    def add_stack
      @values << []
    end

    ##
    # Returns `true` if the stack is empty.
    #
    # @return [TrueClass|FalseClass]
    #
    def empty?
      return @values.empty?
    end

    ##
    # Pushes a value to the current (= last) stack.
    #
    # @param [Mixed] value
    #
    def push(value)
      @values.last << value
    end

    ##
    # Pops the last stack from the collection and returns it.
    #
    # @return [Array]
    #
    def pop
      return @values.pop
    end
  end # NestedStack
end # RubyLint
