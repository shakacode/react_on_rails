unless Object.const_defined? :PryStackExplorer
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry'
end

require 'pry-stack_explorer'

def alpha
  x = "hello"
  beta
  puts x
end

def beta
  binding.pry
end

alpha
