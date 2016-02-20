require 'test_helper'
require 'tins'

class ConcernTest < Test::Unit::TestCase
  module AC
    extend Tins::Concern

    included do
      $included = self
    end

    def foo
      :foo
    end

    module ClassMethods
      def bar
        :bar
      end
    end
  end

  $included = nil

  class A
    include AC
  end

  def test_concern
    a = A.new
    assert_equal A, $included
    assert_equal :foo, a.foo
    assert_equal :bar, A.bar
  end
end
