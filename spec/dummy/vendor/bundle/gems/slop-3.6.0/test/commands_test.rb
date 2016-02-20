require 'helper'

class CommandsTest < TestCase

  def setup
    @opts = Slop.new do |o|
      o.on :v, :version
      o.command :add do |add|
        add.on :v, 'verbose mode'
      end
    end
  end

  test "parse! removes the command AND its options" do
    items = %w'add -v'
    @opts.parse! items
    assert_equal [], items
  end

  test "parse does not remove the command or its options" do
    items = %w'add -v'
    @opts.parse items
    assert_equal ['add', '-v'], items
  end

end
