require 'test_helper'
require 'tins/xt'

module Tins
  class UniqByTest < Test::Unit::TestCase

    unless defined?(Point)
      class Point < Struct.new :x, :y
      end
    end

    def test_uniq_by
      assert_equal [ 1, 2, 3 ], [ 1, 2, 2, 3 ].uniq_by.sort
      a = [ 1, 2, 2, 3 ]; a.uniq_by!
      assert_equal [ 1, 2, 3 ], a.sort
      p1 = Point.new 1, 2
      p2 = Point.new 2, 2
      p3 = Point.new 2, 2
      p4 = Point.new 3, 3
      a = [ p1, p2, p3, p4 ]
      a_uniq = a.uniq_by { |p| p.y }
      assert_equal 2, a_uniq.size
      assert a_uniq.include?(p4)
      assert [ p1, p2, p3 ].any? { |p| a_uniq.include? p }
      a.uniq_by! { |p| p.y }
      assert_equal 2, a.size
      assert a.include?(p4)
      assert [ p1, p2, p3 ].any? { |p| a.include? p }
    end
  end
end
