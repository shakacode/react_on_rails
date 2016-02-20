# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#tell" do
  it "returns the current position of the stream" do
    sio = BinaryStringIO.new
    Archive::Zip::Codec::Store::Compress.open(sio) do |c|
      c.tell.must_equal(0)
      c.write('test1')
      c.tell.must_equal(5)
      c.write('test2')
      c.tell.must_equal(10)
      c.rewind
      c.tell.must_equal(0)
    end
  end

  it "raises IOError on closed stream" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    lambda do
      Archive::Zip::Codec::Store::Compress.open(delegate) { |c| c }.tell
    end.must_raise(IOError)
  end
end
