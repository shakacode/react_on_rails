module Tins
  module StringVersion
    LEVELS  = [ :major, :minor, :build, :revision ].each_with_index.
      each_with_object({}) { |(k, v), h| h[k] = v }.freeze

    SYMBOLS = LEVELS.invert.freeze

    class Version
      include Comparable

      def initialize(string)
        string =~ /\A\d+(\.\d+)*\z/ or
          raise ArgumentError, "#{string.inspect} isn't a version number"
        @version = string.frozen? ? string.dup : string
      end

      LEVELS.each do |symbol, level|
        define_method(symbol) do
          self[level]
        end

        define_method("#{symbol}=") do |new_level|
          self[level] = new_level
        end
      end

      def bump(level = array.size - 1)
        level = level_of(level)
        self[level] += 1
        for l in level.succ..3
          self[l] &&= 0
        end
        self
      end

      def level_of(specifier)
        if specifier.respond_to?(:to_sym)
          LEVELS.fetch(specifier)
        else
          specifier
        end
      end

      def [](level)
        array[level_of(level)]
      end

      def []=(level, value)
        level = level_of(level)
        value = value.to_i
        value >= 0 or raise ArgumentError,
          "version numbers can't contain negative numbers like #{value}"
        a = array
        a[level] = value
        a.map!(&:to_i)
        @version.replace a * ?.
      end

      def succ!
        self[-1] += 1
        self
      end

      def pred!
        self[-1] -= 1
        self
      end

      def <=>(other)
        pairs = array.zip(other.array)
        pairs.map! { |a, b| [ a.to_i, b.to_i ] }
        a, b = pairs.transpose
        a <=> b
      end

      def ==(other)
        (self <=> other).zero?
      end

      def array
        @version.split(?.).map(&:to_i)
      end

      alias to_a array

      def to_s
        @version
      end

      alias inspect to_s
    end

    def version
      Version.new(self)
    end
  end
end

require 'tins/alias'
