#!/usr/bin/env ruby
#
# cd-cause example
#
# Try running with: ./examples/example.rb
#
# When pry opens you can `cd-cause` a few times to see which exception
# triggered all these buggy rescue blocks!
$:.unshift File.expand_path '../../lib', __FILE__
require 'pry-rescue'

Pry.rescue do

  def a
    begin
      begin
        raise "foo"

      rescue => e
        raise "bar"
      end

    rescue => e
      1 / 0

    end
  end
  a
end
