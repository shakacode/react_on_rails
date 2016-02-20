module Byebug
  module Helpers
    #
    # Utilities for interaction with strings
    #
    module StringHelper
      #
      # Converts +str+ from an_underscored-or-dasherized_string to
      # ACamelizedString.
      #
      def camelize(str)
        str.dup.split(/[_-]/).map(&:capitalize).join('')
      end

      #
      # Improves indentation and spacing in +str+ for readability in Byebug's
      # command prompt.
      #
      def prettify(str)
        "\n" + str.gsub(/^ {6}/, '') + "\n"
      end
    end
  end
end
