#!/usr/bin/env ruby
# pry-stack_explorer example
#
# Run with ./examples/example2.rb
#
# When pry opens you'll be able to move "up" and "down" the stack and see
# what's happening at all levels.

$:.unshift File.expand_path '../../lib', __FILE__
require 'pry-rescue'

def alpha
  x = 1
  beta
end

def beta
  y = 30
  gamma(1, 2)
end

def gamma(x)
  greeting = x
end

Pry.rescue do
  alpha
end
