require 'byebug/helpers/parse'

module Byebug
  module Helpers
    #
    # Utilities to assist breakpoint/display enabling/disabling.
    #
    module ToggleHelper
      include ParseHelper

      def enable_disable_breakpoints(is_enable, args)
        return errmsg(pr('toggle.errors.no_breakpoints')) if Breakpoint.none?

        all_breakpoints = Byebug.breakpoints.sort_by(&:id)
        if args.nil?
          selected_breakpoints = all_breakpoints
        else
          selected_ids = []
          args.split(/ +/).each do |pos|
            last_id = all_breakpoints.last.id
            pos, err = get_int(pos, "#{is_enable} breakpoints", 1, last_id)
            return errmsg(err) unless pos

            selected_ids << pos
          end
          selected_breakpoints = all_breakpoints.select do |b|
            selected_ids.include?(b.id)
          end
        end

        selected_breakpoints.each do |b|
          enabled = ('enable' == is_enable)
          if enabled && !syntax_valid?(b.expr)
            return errmsg(pr('toggle.errors.expression', expr: b.expr))
          end

          b.enabled = enabled
        end
      end

      def enable_disable_display(is_enable, args)
        return errmsg(pr('toggle.errors.no_display')) if 0 == n_displays

        selected_displays = args ? args.split(/ +/) : [1..n_displays + 1]

        selected_displays.each do |pos|
          pos, err = get_int(pos, "#{is_enable} display", 1, n_displays)
          return errmsg(err) unless err.nil?

          Byebug.displays[pos - 1][0] = ('enable' == is_enable)
        end
      end

      private

      def n_displays
        Byebug.displays.size
      end
    end
  end
end
