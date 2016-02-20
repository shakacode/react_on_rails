module SimpleCov
  module Formatter
    class HTMLFormatter
      VERSION = "0.10.0"

      def VERSION.to_a
        split(".").map(&:to_i)
      end

      def VERSION.major
        to_a[0]
      end

      def VERSION.minor
        to_a[1]
      end

      def VERSION.patch
        to_a[2]
      end

      def VERSION.pre
        to_a[3]
      end
    end
  end
end
