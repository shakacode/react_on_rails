# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#tell" do
  it "returns the current position of the stream" do
    sio = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(sio) do |e|
      e.tell.must_equal(0)
      e.write('test1')
      e.tell.must_equal(5)
      e.write('test2')
      e.tell.must_equal(10)
      e.rewind
      e.tell.must_equal(0)
    end
  end

  it "raises IOError on closed stream" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    lambda do
      Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) { |e| e }.tell
    end.must_raise(IOError)
  end
end
