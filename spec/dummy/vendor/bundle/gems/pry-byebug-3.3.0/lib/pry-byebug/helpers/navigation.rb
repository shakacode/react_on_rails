module PryByebug
  module Helpers
    #
    # Helpers to aid breaking out of the REPL loop
    #
    module Navigation
      #
      # Breaks out of the REPL loop and signals tracer
      #
      def breakout_navigation(action, options = {})
        _pry_.binding_stack.clear

        throw :breakout_nav, action: action, options: options, pry: _pry_
      end
    end
  end
end
