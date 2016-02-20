#!/usr/bin/env ruby

require 'tins'

LetScope = Tins::BlankSlate.with :instance_eval, :to_s, :inspect, :extend
class LetScope
  include Tins::MethodMissingDelegator::DelegatorModule
  include Tins::BlockSelf

  def initialize(my_self, bindings = {}, outer_scope = nil)
    super(my_self)
    @outer_scope = outer_scope
    @bindings = bindings
    extend Tins::Eigenclass
    eigenclass_eval { extend Tins::Constant }
    each_binding do |name, value|
      eigenclass_eval {  constant name, value }
    end
  end

  def each_binding(&block)
    if @outer_scope
      @outer_scope.each_binding(&block)
    end
    @bindings.each(&block)
  end

  def let(bindings = {}, &block)
    ls = LetScope.new(block_self(&block), bindings, self)
    ls.instance_eval(&block)
  end

  # Including this module into your current namespace defines the let method.
  module Include
    include Tins::BlockSelf

    def let(bindings = {}, &block)
      ls = LetScope.new(block_self(&block), bindings)
      ls.instance_eval(&block)
    end
  end
end

if $0 == __FILE__
  class Foo
    include LetScope::Include

    def twice(x)
      2 * x
    end

    def test
      let x: 1, y: twice(1) do
        let z: twice(x) do
          puts "#{x} * #{y} == #{z} # => #{x * y == twice(x)}"
        end
      end
    end
  end

  Foo.new.test
end
