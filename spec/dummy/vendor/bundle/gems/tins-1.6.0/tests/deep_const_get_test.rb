require 'test_helper'
require 'tins/xt/deep_const_get'

module Tins
  class DeepConstGetTest < Test::Unit::TestCase
    module A
      module B
      end
    end

    module C
      module NotB
      end

      def self.const_missing(c)
        NotB
      end
    end

    def test_deep_const_get_with_start_module
      assert_raise(ArgumentError) { deep_const_get '::B', A }
      assert_equal A::B, deep_const_get('B', A)
    end

    def test_deep_const_get_without_start_module
      assert_equal Tins::DeepConstGetTest::A::B, deep_const_get('::Tins::DeepConstGetTest::A::B')
      assert_equal Tins::DeepConstGetTest::A::B, deep_const_get('Tins::DeepConstGetTest::A::B')
      assert_equal Array, deep_const_get('::Array')
      assert_equal Array, deep_const_get('Array')
    end

    def test_deep_const_get_with_const_missing
      assert_raise(ArgumentError) { deep_const_get '::Tins::DeepConstGetTest::A::D' }
      assert_equal Tins::DeepConstGetTest::C::NotB, deep_const_get('::Tins::DeepConstGetTest::C::B')
    end
  end
end
