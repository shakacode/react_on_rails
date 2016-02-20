module Byebug
  #
  # Reopens the +info+ command to define the +display+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about display expressions
    #
    class DisplayCommand < Command
      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* d(?:isplay)? \s*$/x
      end

      def self.description
        <<-EOD
          inf[o] d[display]

          #{short_description}
        EOD
      end

      def self.short_description
        'List of expressions to display when program stops'
      end

      def execute
        unless Byebug.displays.find { |d| d[0] }
          return puts('There are no auto-display expressions now.')
        end

        puts 'Auto-display expressions now in effect:'
        puts 'Num Enb Expression'

        Byebug.displays.each_with_index do |d, i|
          puts(format('%3d: %s  %s', i + 1, d[0] ? 'y' : 'n', d[1]))
        end
      end
    end
  end
end
