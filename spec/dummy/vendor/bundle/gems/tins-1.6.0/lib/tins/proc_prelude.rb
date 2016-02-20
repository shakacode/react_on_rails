require 'tins/memoize'

module Tins
  module ProcPrelude
    def apply(&my_proc)
      my_proc or raise ArgumentError, 'a block argument is required'
      lambda { |list| my_proc.call(*list) }
    end

    def map_apply(my_method, *args, &my_proc)
      my_proc or raise ArgumentError, 'a block argument is required'
      lambda { |x, y| my_proc.call(x, y.__send__(my_method, *args)) }
    end

    def call(obj, &my_proc)
      my_proc or raise ArgumentError, 'a block argument is required'
      obj.instance_eval(&my_proc)
    end

    def array
      lambda { |*list| list }
    end
    memoize_function :array, :freeze =>  true

    def first
      lambda { |*list| list.first }
    end
    memoize_function :first, :freeze =>  true

    alias head first

    def second
      lambda { |*list| list[1] }
    end
    memoize_function :second, :freeze =>  true

    def tail
      lambda { |*list| list[1..-1] }
    end
    memoize_function :tail, :freeze =>  true

    def last
      lambda { |*list| list.last }
    end
    memoize_function :last, :freeze =>  true

    def rotate(n = 1)
      lambda { |*list| list.rotate(n) }
    end

    alias swap rotate

    def id1
      lambda { |obj| obj }
    end
    memoize_function :id1, :freeze =>  true

    def const(konst = nil, &my_proc)
      konst ||= my_proc.call
      lambda { |*_| konst }
    end

    def nth(n)
      lambda { |*list| list[n] }
    end

    def from(&block)
      my_method, binding = block.call, block.binding
      my_self = eval 'self', binding
      lambda { |*list| my_self.__send__(my_method, *list) }
    end
  end
end
