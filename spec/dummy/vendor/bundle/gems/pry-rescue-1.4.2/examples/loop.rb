#!/usr/bin/env ruby
require 'pry-rescue'

# Peeking example! Try running this example with:
#
# rescue --peek example/loop.rb
#
# Then hit <ctrl-/>, and be able to see what's going on.
#
puts "Hit <ctrl-/> to peek with Pry, or <ctrl+c> to quit."

def r
  some_var = 13
  loop do
    x = File.readlines(__FILE__)
  end
end
r
