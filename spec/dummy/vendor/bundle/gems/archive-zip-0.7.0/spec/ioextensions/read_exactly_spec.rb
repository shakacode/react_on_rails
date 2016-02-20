# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/ioextensions.rb'
require 'archive/support/binary_stringio'

describe "IOExtensions.read_exactly" do
  it "reads and returns length bytes from a given IO object" do
    io = BinaryStringIO.new('This is test data')
    IOExtensions.read_exactly(io, 4).must_equal 'This'
    IOExtensions.read_exactly(io, 13).must_equal ' is test data'
  end

  it "raises an error when too little data is available" do
    io = BinaryStringIO.new('This is test data')
    lambda do
      IOExtensions.read_exactly(io, 18)
    end.must_raise EOFError
  end

  it "takes an optional buffer argument and fills it" do
    io = BinaryStringIO.new('This is test data')
    buffer = ''
    IOExtensions.read_exactly(io, 4, buffer)
    buffer.must_equal 'This'
    buffer = ''
    IOExtensions.read_exactly(io, 13, buffer)
    buffer.must_equal ' is test data'
  end

  it "empties the optional buffer before filling it" do
    io = BinaryStringIO.new('This is test data')
    buffer = ''
    IOExtensions.read_exactly(io, 4, buffer)
    buffer.must_equal 'This'
    IOExtensions.read_exactly(io, 13, buffer)
    buffer.must_equal ' is test data'
  end

  it "can read 0 bytes" do
    io = BinaryStringIO.new('This is test data')
    IOExtensions.read_exactly(io, 0).must_equal ''
  end

  it "retries partial reads" do
    io = MiniTest::Mock.new
    io.expect(:read, 'hello', [10])
    io.expect(:read, 'hello', [5])
    IOExtensions.read_exactly(io, 10).must_equal 'hellohello'
  end
end
