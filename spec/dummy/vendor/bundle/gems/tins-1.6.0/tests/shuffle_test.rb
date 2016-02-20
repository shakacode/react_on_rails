require 'test_helper'
require 'tins/xt'

module Tins
  if Tins::Shuffle === Array
    class ShuffleTest < Test::Unit::TestCase

      def setup
        @a = [ 1, 2, 3 ]
        srand 666
      end

      def test_shuffle
        assert_equal(a = [2, 3, 1], a = @a.shuffle)
        assert_not_same @a, a
        assert_equal(b = [3, 1, 2], b = @a.shuffle)
        assert_not_same a, b
        assert_not_same @a, b
      end

      def test_shuffle_bang
        assert_equal([2, 3, 1], a = @a.shuffle!)
        assert_same @a, a
        assert_equal([1, 2, 3], b = @a.shuffle!)
        assert_same a, b
        assert_same @a, b
      end
    end
  end
end
