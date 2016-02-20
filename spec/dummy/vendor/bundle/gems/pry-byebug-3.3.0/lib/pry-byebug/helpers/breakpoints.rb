require 'byebug'

module PryByebug
  module Helpers
    #
    # Common helpers for breakpoint related commands
    #
    module Breakpoints
      #
      # Byebug's array of breakpoints.
      #
      def breakpoints
        Pry::Byebug::Breakpoints
      end

      #
      # Current file in the target binding. Used as the default breakpoint
      # location.
      #
      def current_file
        target.eval('__FILE__')
      end

      #
      # Prints a message with bold font.
      #
      def bold_puts(msg)
        output.puts(text.bold(msg))
      end

      #
      # Print out full information about a breakpoint.
      #
      # Includes surrounding code at that point.
      #
      def print_full_breakpoint(br)
        header = "Breakpoint #{br.id}:"
        status = br.enabled? ? 'Enabled' : 'Disabled'
        code = br.source_code.with_line_numbers.to_s
        condition = br.expr ? "#{text.bold('Condition:')} #{br.expr}\n" : ''

        output.puts <<-EOP.gsub(/ {8}/, '')

          #{text.bold(header)} #{br} (#{status}) #{condition}

          #{code}

        EOP
      end

      #
      # Print out concise information about a breakpoint.
      #
      def print_short_breakpoint(breakpoint)
        id = format('%*d', max_width, breakpoint.id)
        status = breakpoint.enabled? ? 'Yes' : 'No '
        expr = breakpoint.expr ? " #{breakpoint.expr} " : ''

        output.puts("  #{id} #{status}     #{breakpoint}#{expr}")
      end

      #
      # Prints a header for the breakpoint list.
      #
      def print_breakpoints_header
        header = "#{' ' * (max_width - 1)}# Enabled At "

        output.puts <<-EOP.gsub(/ {8}/, '')

          #{text.bold(header)}
          #{text.bold('-' * header.size)}

        EOP
      end

      #
      # Max width of breakpoints id column
      #
      def max_width
        breakpoints.last ? breakpoints.last.id.to_s.length : 1
      end
    end
  end
end
