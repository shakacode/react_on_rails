module RSpec
  module Matchers
    # Facilitates converting ruby objects to English phrases.
    module EnglishPhrasing
      # Converts a symbol into an English expression.
      #
      #     split_words(:banana_creme_pie) #=> "banana creme pie"
      #
      def self.split_words(sym)
        sym.to_s.gsub(/_/, ' ')
      end

      # @note The returned string has a leading space except
      # when given an empty list.
      #
      # Converts an object (often a collection of objects)
      # into an English list.
      #
      #     list(['banana', 'kiwi', 'mango'])
      #     #=> " \"banana\", \"kiwi\", and \"mango\""
      #
      # Given an empty collection, returns the empty string.
      #
      #     list([]) #=> ""
      #
      def self.list(obj)
        return " #{RSpec::Support::ObjectFormatter.format(obj)}" if !obj || Struct === obj
        items = Array(obj).map { |w| RSpec::Support::ObjectFormatter.format(w) }
        case items.length
        when 0
          ""
        when 1
          " #{items[0]}"
        when 2
          " #{items[0]} and #{items[1]}"
        else
          " #{items[0...-1].join(', ')}, and #{items[-1]}"
        end
      end
    end
  end
end
