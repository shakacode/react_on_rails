$VERBOSE = true

require 'slop'

require 'minitest/autorun'
require 'stringio'

class TestCase < Minitest::Test
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
  end
end