module RubyLint
  module MethodCall
    ##
    # The AssignMember class is used for evaluating object member assignments.
    # This includes the following types of assignments:
    #
    # * Array index assignments
    # * Hash key assignments
    #
    class AssignMember < Base
      ##
      # @see Base#evaluate
      #
      def evaluate(arguments, context, block = nil)
        return if context.frozen?

        *members, values = arguments
        member_values    = prepare_values(values)

        members.each do |member|
          member = create_member(member.value.to_s, member_values.shift)

          context.add_definition(member)
        end
      end

      private

      ##
      # @param [String] name
      # @param [Mixed] value
      # @return [RubyLint::Definition::RubyObject]
      #
      def create_member(name, value)
        return Definition::RubyObject.new(
          :name  => name,
          :type  => :member,
          :value => value
        )
      end

      ##
      # @param [Array] values
      # @return [Array]
      #
      def prepare_values(values)
        if values and values.array?
          member_values = values.list(:member).map(&:value)
        elsif values
          member_values = [values]
        end

        return member_values
      end
    end # AssignMember
  end # MethodCall
end # RubyLint
