module Libv8
  module Compiler
    class Clang < GenericCompiler
      VERSION_REGEXP = /clang version (\d+\.\d+(\.\d+)*) \(/i

      def name
        'clang'
      end

      def compatible?
        version >= '3.1'
      end
    end
  end
end
