module Term
  module ANSIColor
    class PPMReader
      include Term::ANSIColor

      def initialize(io, options = {})
        @io      = io
        @options = options
        @buffer  = ''
      end

      def reset_io
        begin
          @io.rewind
        rescue Errno::ESPIPE
        end
        parse_header
      end

      def each_row
        reset_io
        @height.times do
          yield parse_row
        end
      end

      def to_a
        enum_for(:each_row).to_a
      end

      def to_s
        result = ''
        each_row do |row|
          last_pixel = nil
          for pixel in row
            if pixel != last_pixel
              color = Attribute.nearest_rgb_color(pixel, @options)
              result << on_color(color)
              last_pixel = pixel
            end
            result << ' '
          end
          result << reset << "\n"
        end
        result
      end

      private

      def parse_row
        row = []
        @width.times do
          row << parse_next_pixel
        end
        row
      end

      def parse_next_pixel
        pixel = nil
        case @type
        when 3
          @buffer.empty? and @buffer << next_line
          @buffer.sub!(/(\d+)\s+(\d+)\s+(\d+)\s*/) do
            pixel = [ $1.to_i, $2.to_i, $3.to_i ]
            ''
          end
        when 6
          @buffer.size < 3 and @buffer << @io.read(8192)
          pixel = @buffer.slice!(0, 3).unpack('C3')
        end
        pixel
      end

      def parse_header
        (line = next_line) =~ /^P([36])$/ or raise "unknown type #{line.to_s.chomp.inspect}"
        @type = $1.to_i

        if next_line =~ /^(\d+)\s+(\d+)$/
          @width, @height = $1.to_i, $2.to_i
        else
          raise "missing dimensions"
        end

        unless next_line =~ /^255$/
          raise "only 255 max color images allowed"
        end
      end

      def next_line
        while line = @io.gets and line =~ /^#|^\s$/
        end
        line
      end
    end
  end
end
