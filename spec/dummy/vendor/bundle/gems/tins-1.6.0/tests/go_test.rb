require 'test_helper'
require 'tins/go'

module Tins
  class GoTest < Test::Unit::TestCase
    include Tins::GO


    def test_empty_string
      r = go '', args = %w[a b c]
      assert_equal({}, r)
      assert_equal %w[a b c], args
    end

    def test_empty_args
      r = go 'ab:', args = []
      assert_equal({ 'a' => false, 'b' => nil }, r)
      assert_equal [], args
    end

    def test_simple
      r = go 'ab:', args = %w[-b hello -a -c rest]
      assert_equal({ 'a' => 1, 'b' => 'hello' }, r)
      assert_equal %w[-c rest], args
    end

    def test_complex
      r = go 'ab:', args = %w[-a -b hello -a -bworld -c rest]
      assert_equal({ 'a' => 2, 'b' => 'hello' }, r)
      assert_equal %w[hello world], r['b'].to_a
      assert_equal %w[-c rest], args
    end

    def test_complex2
      r = go 'ab:', args = %w[-b hello -aa -b world -c rest]
      assert_equal({ 'a' => 2, 'b' => 'hello' }, r)
      assert_equal %w[hello world], r['b'].to_a
      assert_equal %w[-c rest], args
    end

    def test_complex_frozen
      args = %w[-b hello -aa -b world -c rest]
      args = args.map(&:freeze)
      r = go 'ab:', args
      assert_equal({ 'a' => 2, 'b' => 'hello' }, r)
      assert_equal %w[hello world], r['b'].to_a
      assert_equal %w[-c rest], args
    end
  end
end
