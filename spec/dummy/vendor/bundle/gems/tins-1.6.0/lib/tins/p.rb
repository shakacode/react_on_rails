require 'pp'

module Tins
  module P
    private

    # Raise a runtime error with the inspected objects +objs+ (obtained by
    # calling the #inspect method) as their message text. This is useful for
    # quick debugging.
    def p!(*objs)
      raise((objs.size < 2 ? objs.first : objs).inspect)
    end

    # Raise a runtime error with the inspected objects +objs+ (obtained by
    # calling the #pretty_inspect method) as their message text. This is useful
    # for quick debugging.
    def pp!(*objs)
      raise("\n" + (objs.size < 2 ? objs.first : objs).pretty_inspect.chomp)
    end
  end
end

require 'tins/alias'
