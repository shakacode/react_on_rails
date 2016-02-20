module PryByebug
  module Helpers
    #
    # Helpers to help handling multiline inputs
    #
    module Multiline
      #
      # Returns true if we are in a multiline context and, as a side effect,
      # updates the partial evaluation string with the current input.
      #
      # Returns false otherwise
      #
      def check_multiline_context
        return false if eval_string.empty?

        eval_string.replace("#{eval_string}#{match} #{arg_string}\n")
        true
      end
    end
  end
end
