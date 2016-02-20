require 'test_helper'
require 'tins/xt'

module Tins
  class CountByTest < Test::Unit::TestCase

    def test_count_by
      assert_equal 0, [].count_by { |x| x % 2 == 0 }
      assert_equal 0, [ 1 ].count_by { |x| x % 2 == 0 }
      assert_equal 1, [ 1 ].count_by { |x| x % 2 == 1 }
      assert_equal 1, [ 1, 2 ].count_by { |x| x % 2 == 0 }
      assert_equal 1, [ 1, 2 ].count_by { |x| x % 2 == 1 }
      assert_equal 2, [ 1, 2, 3, 4, 5 ].count_by { |x| x % 2 == 0 }
      assert_equal 3, [ 1, 2, 3, 4, 5 ].count_by { |x| x % 2 == 1 }
    end
  end
end
