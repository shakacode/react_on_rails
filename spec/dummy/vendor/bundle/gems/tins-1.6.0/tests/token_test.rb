require 'test_helper'
require 'tins'

module Tins
  class TokenTest < Test::Unit::TestCase
    def test_token_failures
      assert_raises(ArgumentError) { Tins::Token.new(:bits => 0) }
      assert_raises(ArgumentError) { Tins::Token.new(:length => 0) }
      assert_raises(ArgumentError) { Tins::Token.new(:alphabet => %w[0]) }
    end

    def test_token_for_length
      token = Tins::Token.new(:length => 22)
      assert_equal 22, token.length
      assert_equal 130, token.bits
    end

    def test_token_for_bits
      token = Tins::Token.new(:bits => 128)
      assert_equal 22, token.length
      # can differ from bits argument depending on alphabet:
      assert_equal 130, token.bits
    end

    def test_alphabet
      token = Tins::Token.new(:alphabet => %w[0 1])
      assert_equal 128, token.length
      assert_equal 128, token.bits
      token = Tins::Token.new(:alphabet => %w[0 1 2 3])
      assert_equal 64, token.length
      assert_equal 128, token.bits
      token = Tins::Token.new(:length => 128, :alphabet => %w[0 1 2 3])
      assert_equal 128, token.length
      assert_equal 256, token.bits
    end
  end
end

