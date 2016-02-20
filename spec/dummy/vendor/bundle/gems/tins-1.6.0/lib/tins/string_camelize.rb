module Tins
  module StringCamelize
    def camelize(first_letter = :upper)
      case first_letter
      when :upper, true
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      when :lower, false
        self[0].chr.downcase + camelize[1..-1]
      end
    end

    alias camelcase camelize
  end
end

require 'tins/alias'
