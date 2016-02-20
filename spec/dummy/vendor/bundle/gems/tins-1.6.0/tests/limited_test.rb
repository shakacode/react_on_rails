require 'test_helper'
require 'tins'

module Tins
  class LimitedTest < Test::Unit::TestCase
    class ::Array
      include Tins::Shuffle
    end

    def test_limited
      count = {}
      limited = Tins::Limited.new(5)
      5.times do
        limited.execute do
          count[Thread.current] = true
          sleep
        end
      end
      until count.size >= 5
        sleep 0.1
      end
      assert_equal 5, count.keys.uniq.size
    end
  end
end
