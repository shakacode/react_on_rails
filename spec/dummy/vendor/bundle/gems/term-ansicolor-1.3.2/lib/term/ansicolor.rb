module Term

  # The ANSIColor module can be used for namespacing and mixed into your own
  # classes.
  module ANSIColor
    require 'term/ansicolor/version'
    require 'term/ansicolor/attribute'
    require 'term/ansicolor/rgb_triple'
    require 'term/ansicolor/ppm_reader'

    Attribute.set :clear             ,   0 # String#clear is already used to empty string in Ruby 1.9
    Attribute.set :reset             ,   0 # synonym for :clear
    Attribute.set :bold              ,   1
    Attribute.set :dark              ,   2
    Attribute.set :faint             ,   2
    Attribute.set :italic            ,   3 # not widely implemented
    Attribute.set :underline         ,   4
    Attribute.set :underscore        ,   4 # synonym for :underline
    Attribute.set :blink             ,   5
    Attribute.set :rapid_blink       ,   6 # not widely implemented
    Attribute.set :negative          ,   7 # no reverse because of String#reverse
    Attribute.set :concealed         ,   8
    Attribute.set :strikethrough     ,   9 # not widely implemented

    Attribute.set :black             ,  30
    Attribute.set :red               ,  31
    Attribute.set :green             ,  32
    Attribute.set :yellow            ,  33
    Attribute.set :blue              ,  34
    Attribute.set :magenta           ,  35
    Attribute.set :cyan              ,  36
    Attribute.set :white             ,  37

    Attribute.set :on_black          ,  40
    Attribute.set :on_red            ,  41
    Attribute.set :on_green          ,  42
    Attribute.set :on_yellow         ,  43
    Attribute.set :on_blue           ,  44
    Attribute.set :on_magenta        ,  45
    Attribute.set :on_cyan           ,  46
    Attribute.set :on_white          ,  47

    # High intensity, aixterm (works in OS X)
    Attribute.set :intense_black     ,  90
    Attribute.set :bright_black      ,  90
    Attribute.set :intense_red       ,  91
    Attribute.set :bright_red        ,  91
    Attribute.set :intense_green     ,  92
    Attribute.set :bright_green      ,  92
    Attribute.set :intense_yellow    ,  93
    Attribute.set :bright_yellow     ,  93
    Attribute.set :intense_blue      ,  94
    Attribute.set :bright_blue       ,  94
    Attribute.set :intense_magenta   ,  95
    Attribute.set :bright_magenta    ,  95
    Attribute.set :intense_cyan      ,  96
    Attribute.set :bright_cyan       ,  96
    Attribute.set :intense_white     ,  97
    Attribute.set :bright_white      ,  97

    # High intensity background, aixterm (works in OS X)
    Attribute.set :on_intense_black  , 100
    Attribute.set :on_bright_black   , 100
    Attribute.set :on_intense_red    , 101
    Attribute.set :on_bright_red     , 101
    Attribute.set :on_intense_green  , 102
    Attribute.set :on_bright_green   , 102
    Attribute.set :on_intense_yellow , 103
    Attribute.set :on_bright_yellow  , 103
    Attribute.set :on_intense_blue   , 104
    Attribute.set :on_bright_blue    , 104
    Attribute.set :on_intense_magenta, 105
    Attribute.set :on_bright_magenta , 105
    Attribute.set :on_intense_cyan   , 106
    Attribute.set :on_bright_cyan    , 106
    Attribute.set :on_intense_white  , 107
    Attribute.set :on_bright_white   , 107

    Attribute.set :color0, 0, :html => '#000000'
    Attribute.set :color1, 1, :html => '#800000'
    Attribute.set :color2, 2, :html => '#808000'
    Attribute.set :color3, 3, :html => '#808000'
    Attribute.set :color4, 4, :html => '#000080'
    Attribute.set :color5, 5, :html => '#800080'
    Attribute.set :color6, 6, :html => '#008080'
    Attribute.set :color7, 7, :html => '#c0c0c0'

    Attribute.set :color8, 8, :html => '#808080'
    Attribute.set :color9, 9, :html => '#ff0000'
    Attribute.set :color10, 10, :html => '#00ff00'
    Attribute.set :color11, 11, :html => '#ffff00'
    Attribute.set :color12, 12, :html => '#0000ff'
    Attribute.set :color13, 13, :html => '#ff00ff'
    Attribute.set :color14, 14, :html => '#00ffff'
    Attribute.set :color15, 15, :html => '#ffffff'

    steps = [ 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff ]

    for i in 16..231
      red, green, blue = (i - 16).to_s(6).rjust(3, '0').each_char.map { |c| steps[c.to_i] }
      Attribute.set "color#{i}", i, :red => red, :green => green, :blue => blue
    end

    grey = 8
    for i in 232..255
      Attribute.set "color#{i}", i, :red => grey, :green => grey, :blue => grey
      grey += 10
    end

    Attribute.set :on_color0, 0, :html => '#000000'
    Attribute.set :on_color1, 1, :html => '#800000'
    Attribute.set :on_color2, 2, :html => '#808000'
    Attribute.set :on_color3, 3, :html => '#808000'
    Attribute.set :on_color4, 4, :html => '#000080'
    Attribute.set :on_color5, 5, :html => '#800080'
    Attribute.set :on_color6, 6, :html => '#008080'
    Attribute.set :on_color7, 7, :html => '#c0c0c0'

    Attribute.set :on_color8, 8, :html => '#808080'
    Attribute.set :on_color9, 9, :html => '#ff0000'
    Attribute.set :on_color10, 10, :html => '#00ff00'
    Attribute.set :on_color11, 11, :html => '#ffff00'
    Attribute.set :on_color12, 12, :html => '#0000ff'
    Attribute.set :on_color13, 13, :html => '#ff00ff'
    Attribute.set :on_color14, 14, :html => '#00ffff'
    Attribute.set :on_color15, 15, :html => '#ffffff'

    steps = [ 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff ]

    for i in 16..231
      red, green, blue = (i - 16).to_s(6).rjust(3, '0').each_char.map { |c| steps[c.to_i] }
      Attribute.set "on_color#{i}", i, :red => red, :green => green, :blue => blue
    end

    grey = 8
    for i in 232..255
      Attribute.set "on_color#{i}", i, :red => grey, :green => grey, :blue => grey
      grey += 10
    end

    # :stopdoc:
    ATTRIBUTE_NAMES = Attribute.named_attributes.map(&:name)
    # :startdoc:

    # Returns true if Term::ANSIColor supports the +feature+.
    #
    # The feature :clear, that is mixing the clear color attribute into String,
    # is only supported on ruby implementations, that do *not* already
    # implement the String#clear method. It's better to use the reset color
    # attribute instead.
    def support?(feature)
      case feature
      when :clear
        !String.instance_methods(false).map(&:to_sym).include?(:clear)
      end
    end
    # Returns true, if the coloring function of this module
    # is switched on, false otherwise.
    def self.coloring?
      @coloring
    end

    # Turns the coloring on or off globally, so you can easily do
    # this for example:
    #  Term::ANSIColor::coloring = STDOUT.isatty
    def self.coloring=(val)
      @coloring = val
    end
    self.coloring = true

    def self.create_color_method(color_name, color_value)
      module_eval <<-EOT
        def #{color_name}(string = nil, &block)
          color(:#{color_name}, string, &block)
        end
      EOT
      self
    end

    for attribute in Attribute.named_attributes
       create_color_method(attribute.name, attribute.code)
    end

    # Regular expression that is used to scan for ANSI-Attributes while
    # uncoloring strings.
    COLORED_REGEXP = /\e\[(?:(?:[349]|10)[0-7]|[0-9]|[34]8;5;\d{1,3})?m/

    # Returns an uncolored version of the string, that is all
    # ANSI-Attributes are stripped from the string.
    def uncolor(string = nil) # :yields:
      if block_given?
        yield.to_str.gsub(COLORED_REGEXP, '')
      elsif string.respond_to?(:to_str)
        string.to_str.gsub(COLORED_REGEXP, '')
      elsif respond_to?(:to_str)
        to_str.gsub(COLORED_REGEXP, '')
      else
        ''
      end
    end

    alias uncolored uncolor

    # Return +string+ or the result string of the given +block+ colored with
    # color +name+. If string isn't a string only the escape sequence to switch
    # on the color +name+ is returned.
    def color(name, string = nil, &block)
      attribute = Attribute[name] or raise ArgumentError, "unknown attribute #{name.inspect}"
      result = ''
      result << "\e[#{attribute.code}m" if Term::ANSIColor.coloring?
      if block_given?
        result << yield
      elsif string.respond_to?(:to_str)
        result << string.to_str
      elsif respond_to?(:to_str)
        result << to_str
      else
        return result #only switch on
      end
      result << "\e[0m" if Term::ANSIColor.coloring?
      result
    end

    def on_color(name, string = nil, &block)
      attribute = Attribute[name] or raise ArgumentError, "unknown attribute #{name.inspect}"
      color("on_#{attribute.name}", string, &block)
    end

    class << self
      # Returns an array of all Term::ANSIColor attributes as symbols.
      def term_ansicolor_attributes
        ::Term::ANSIColor::ATTRIBUTE_NAMES
      end

      alias attributes term_ansicolor_attributes
    end

    # Returns an array of all Term::ANSIColor attributes as symbols.
    def  term_ansicolor_attributes
      ::Term::ANSIColor.term_ansicolor_attributes
    end

    alias attributes term_ansicolor_attributes

    extend self
  end
end
