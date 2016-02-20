module Tins
  unless ::Symbol.method_defined?(:to_proc)
    # :nocov:
    class ::Symbol
      include ToProc
    end
  end
end
