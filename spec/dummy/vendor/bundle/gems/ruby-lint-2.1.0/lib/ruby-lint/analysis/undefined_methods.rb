module RubyLint
  module Analysis
    ##
    # The UndefinedMethods class checks for the use of undefined methods/local
    # variables and adds errors whenever needed. Based on the receiver of a
    # method call the corresponding error message differs to make it easier to
    # understand what is going on.
    #
    # A simple example:
    #
    #     foobar        # => undefined method foobar
    #     'test'.foobar # => undefined method foobar on an instance of String
    #
    class UndefinedMethods < Base
      register 'undefined_methods'

      ##
      # @param [RubyLint::AST::Node] node
      #
      def on_send(node)
        receiver, name, _  = *node

        receiver = unpack_block(receiver)
        name     = name.to_s
        scope    = current_scope

        if receiver and vm.associations.key?(receiver)
          scope = vm.associations[receiver]

          # TODO: this should be handled in a more generic and especially in a
          # more nicer way.
          return if scope.parents.empty?
        end

        unless has_definition?(scope, name)
          message = error_for(name, receiver, scope)

          error(message, node)
        end
      end

      private

      ##
      # @param [RubyLint::Definition::RubyObject] scope
      # @param [String] name
      #
      def has_definition?(scope, name)
        type   = scope.method_call_type
        exists = scope.has_definition?(type, name)

        # Due to the way `parser` wraps block nodes (`(block (send) ...)`
        # opposed to `(send ... (block))`) we'll try to find the method in the
        # previous scope if we can't find it in the current block scope.
        if !exists and scope.block?
          prev   = previous_scope
          exists = prev.has_definition?(prev.method_call_type, name)
        end

        # If method_missing is defined we'll assume the method calls are
        # handled gracefully and not add any errors for them.
        if !exists and scope.has_definition?(type, 'method_missing')
          exists = true
        end

        return exists
      end

      ##
      # Determines what error message to use for a method call.
      #
      # @param [String] name The name of the method.
      # @param [RubyLint::AST::Node] receiver The receiver node, if any.
      # @param [RubyLint::Definition::RubyObject] scope The scope the method
      #  was called on.
      # @return [String]
      #
      def error_for(name, receiver, scope)
        return receiver ? receiver_error(name, scope) : method_error(name)
      end

      ##
      # @param [String] name
      # @return [String]
      #
      def method_error(name)
        return "undefined method #{name}"
      end

      ##
      # Returns a String containing the error message to use when calling an
      # undefined method on a receiver.
      #
      # @param [String] name
      # @param [RubyLint::Definition::RubyObject] scope
      # @return [String]
      #
      def receiver_error(name, scope)
        klass = class_names_for_object(scope)

        if scope.instance?
          error = "undefined method #{name} on an instance of #{klass}"
        else
          error = "undefined method #{name} on #{scope.name}"
        end

        return error
      end

      private

      ##
      # @param [RubyLint::Definition::RubyObject] object
      # @return [String]
      #
      def class_names_for_object(object)
        if object.parents.empty?
          klass = object.ruby_class ? object.ruby_class : object.name
        else
          klass = name_for_parents(object.parents)
        end

        return klass
      end

      ##
      # @param [Array] parents
      # @return [String]
      #
      def name_for_parents(parents)
        return parents[0].name if parents.length == 1

        segments = parents[0..-2].map(&:name)

        return segments.join(', ') + " or #{parents[-1].name}"
      end
    end # UndefinedMethods
  end # Analysis
end # RubyLint
