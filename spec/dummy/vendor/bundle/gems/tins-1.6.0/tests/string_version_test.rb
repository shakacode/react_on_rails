require 'test_helper'
require 'tins'

module Tins
  class StringVersionTest < Test::Unit::TestCase
    def test_comparison
      assert_operator '1.2'.version, :<, '1.3'.version
      assert_operator '1.3'.version, :>, '1.2'.version
      assert_operator '1.2'.version, :<=, '1.2'.version
      assert_operator '1.2'.version, :>=, '1.2'.version
      assert_operator '1.2'.version, :==, '1.2'.version
    end

    def test_change
      s = '1.2'
      s.version.revision = 1
      assert_equal '1.2.0.1', s
      s.version.revision += 1
      assert_equal '1.2.0.2', s
      s.version.succ!
      assert_equal '1.2.0.3', s
      s.version.pred!
      assert_equal '1.2.0.2', s
      assert_raise(ArgumentError) { s.version.build -= 1 }
      s.version.major = 2
      assert_equal '2.2.0.2', s
      s.version.minor = 1
      assert_equal '2.1.0.2', s
    end

    def test_bump
      s = '1.2.3'
      assert_equal '2.0.0', s.version.bump(:major).to_s
      s = '1.2.3'
      assert_equal '1.3.0', s.version.bump(:minor).to_s
      s = '1.2.3'
      assert_equal '1.2.4', s.version.bump(:build).to_s
      s = '1.2.3'
      assert_equal '1.2.4', s.version.bump.to_s
    end
  end
end
