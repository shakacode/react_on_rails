#!/usr/bin/env ruby
#
# You'll need to 'apt-get install libsigsegv-dev' or 'brew install libsigsegv',
# then 'gem install neversaydie' (https://github.com/tenderlove/neversaydie)
#
# Then just run this program:
#
# ./examples/sigsegv.rb
#
# And watch as NeverSayDie tries to read a NULL pointer.
#
require 'neversaydie'
require 'pry-rescue'

class A #< BasicObject
  def oops
    foo = 1
    NeverSayDie.segv
  end
end

Pry::rescue do
  A.new.oops
end
