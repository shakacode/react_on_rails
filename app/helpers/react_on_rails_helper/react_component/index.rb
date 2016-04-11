require "forwardable"

module ReactOnRailsHelper
  module ReactComponent
    class Index
      extend Forwardable

      FIRST = 0
      LAST = Float::INFINITY
      RANGE = (FIRST..LAST)

      def_delegator :enumerator, :next

      def initialize
        @enumerator = RANGE.to_enum
      end

      private

      attr_reader :enumerator
    end
  end
end
