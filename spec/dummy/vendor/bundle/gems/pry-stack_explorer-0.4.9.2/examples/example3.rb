unless Object.const_defined? :PryStackExplorer
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry'
end

require 'pry-stack_explorer'

def b
  x = 30
  proc {
    c
  }.call
end

def c
  u = 50
  V.new.beta
end

# hello
class V
  def beta
    gamma
  end

  def gamma
    zeta
  end
end

def zeta
  vitamin = 100
  binding.pry
end
#

proc {
  class J
    def alphabet(y)
      x = 20
      b
    end
  end
}.call

J.new.alphabet(122)
