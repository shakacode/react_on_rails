module Term
  module ANSIColor
    class Attribute
      @__store__ = {}

      if RUBY_VERSION < '1.9'
        @__order__ = []

        def self.set(name, code, options = {})
          name = name.to_sym
          result = @__store__[name] = new(name, code, options)
          @__order__ << name
          @rgb_colors = nil
          result
        end

        def self.attributes(&block)
          @__order__.map { |name| @__store__[name] }
        end
      else
        def self.set(name, code, options = {})
          name = name.to_sym
          result = @__store__[name] = new(name, code, options)
          @rgb_colors = nil
          result
        end

        def self.attributes(&block)
          @__store__.each_value(&block)
        end
      end

      def self.[](name)
        case
        when self === name                              then name
        when Array === name                             then nearest_rgb_color name
        when name.to_s =~ /\A(on_)?(\d+)\z/             then get "#$1color#$2"
        when name.to_s =~ /\A#([0-9a-f]{3}){1,2}\z/i    then nearest_rgb_color name
        when name.to_s =~ /\Aon_#([0-9a-f]{3}){1,2}\z/i then nearest_rgb_on_color name
        else                                            get name
        end
      end

      def self.get(name)
        @__store__[name.to_sym]
      end

      def self.rgb_colors(&block)
        @rgb_colors ||= attributes.select(&:rgb_color?).each(&block)
      end

      def self.named_attributes(&block)
        @named_attributes ||= attributes.reject(&:rgb_color?).each(&block)
      end

      def self.nearest_rgb_color(color, options = {})
        rgb = RGBTriple[color]
        colors = rgb_colors
        if options.key?(:gray) && !options[:gray]
          colors = colors.reject(&:gray?)
        end
        colors.reject(&:background?).min_by { |c| c.distance_to(rgb, options) }
      end

      def self.nearest_rgb_on_color(color, options = {})
        rgb = RGBTriple[color]
        colors = rgb_colors
        if options.key?(:gray) && !options[:gray]
          colors = colors.reject(&:gray?)
        end
        colors.select(&:background?).min_by { |c| c.distance_to(rgb, options) }
      end

      def initialize(name, code, options = {})
        @name = name.to_sym
        @code = code.to_s
        if html = options[:html]
          @rgb = RGBTriple.from_html(html)
        elsif !options.empty?
          @rgb = RGBTriple.from_hash(options)
        else
          @rgb = nil # prevent instance variable not initialized warnings
        end
      end

      attr_reader :name

      def code
        if rgb_color?
          background? ? "48;5;#{@code}" : "38;5;#{@code}"
        else
          @code
        end
      end

      def apply(string = nil, &block)
        ::Term::ANSIColor.color(self, string, &block)
      end

      def background?
        @name.to_s.start_with?('on_')
      end

      attr_reader :rgb

      def rgb_color?
        !!@rgb
      end

      def gray?
        rgb_color? && to_rgb_triple.gray?
      end

      def to_rgb_triple
        @rgb
      end

      def distance_to(other, options = {})
        if our_rgb = to_rgb_triple and
          other.respond_to?(:to_rgb_triple) and
          other_rgb = other.to_rgb_triple
        then
          our_rgb.distance_to(other_rgb, options)
        else
          1 / 0.0
        end
      end

      def gradient_to(other, options = {})
        if our_rgb = to_rgb_triple and
          other.respond_to?(:to_rgb_triple) and
          other_rgb = other.to_rgb_triple
        then
          our_rgb.gradient_to(other_rgb, options).map do |rgb_triple|
            self.class.nearest_rgb_color(rgb_triple, options)
          end
        else
          []
        end
      end
    end
  end
end
