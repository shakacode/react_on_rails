require 'term/ansicolor/rgb_color_metrics'

module Term
  module ANSIColor
    class RGBTriple
      include Term::ANSIColor::RGBColorMetricsHelpers::WeightedEuclideanDistance

      def self.convert_value(color)
        color.nil? and raise ArgumentError, "missing color value"
        color = Integer(color)
        (0..0xff) === color or raise ArgumentError,
          "color value #{color.inspect} not between 0 and 255"
        color
      end

      private_class_method :convert_value

      def self.from_html(html)
        case html
        when /\A#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/i
          new(*$~.captures.map { |c| convert_value(c.to_i(16)) })
        when /\A#([0-9a-f])([0-9a-f])([0-9a-f])\z/i
          new(*$~.captures.map { |c| convert_value(c.to_i(16) << 4) })
        end
      end

      def self.from_hash(options)
        new(
          convert_value(options[:red]),
          convert_value(options[:green]),
          convert_value(options[:blue])
        )
      end

      def self.from_array(array)
        new(*array)
      end

      def self.[](thing)
        case
        when thing.respond_to?(:to_rgb_triple) then thing
        when thing.respond_to?(:to_ary)        then RGBTriple.from_array(thing.to_ary)
        when thing.respond_to?(:to_str)        then RGBTriple.from_html(thing.to_str.sub(/\Aon_/, '')) # XXX somewhat hacky
        when thing.respond_to?(:to_hash)       then RGBTriple.from_hash(thing.to_hash)
        else raise ArgumentError, "cannot convert #{thing.inspect} into #{self}"
        end
      end

      def initialize(red, green, blue)
        @values = [ red, green, blue ]
      end

      def red
        @values[0]
      end

      def green
        @values[1]
      end

      def blue
        @values[2]
      end

      def gray?
        red != 0 && red != 0xff && red == green && green == blue && blue == red
      end

      def html
        s = '#'
        @values.each { |c| s << '%02x' % c }
        s
      end

      def to_rgb_triple
        self
      end

      attr_reader :values
      protected :values

      def to_a
        @values.dup
      end

      def ==(other)
        @values == other.values
      end

      def distance_to(other, options = {})
        options[:metric] ||= RGBColorMetrics::CIELab
        options[:metric].distance(self, other)
      end

      def initialize_copy(other)
        r = super
        other.instance_variable_set :@values, @values.dup
        r
      end

      def gradient_to(other, options = {})
        options[:steps] ||= 16
        steps = options[:steps].to_i
        steps < 2 and raise ArgumentError, 'at least 2 steps are required'
        changes = other.values.zip(@values).map { |x, y| x - y }
        current = self
        gradient = [ current.dup ]
        s = steps - 1
        while s > 1
          current = current.dup
          gradient << current
          3.times do |i|
            current.values[i] += changes[i] / (steps - 1)
          end
          s -= 1
        end
        gradient << other
      end
    end
  end
end
