# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    sio = BinaryStringIO.new
    Archive::Zip::Codec::Store::Compress.open(sio) do |c|
      c.write('test')
      c.rewind
      c.write(StoreSpecs.test_data)
    end
    sio.string.must_equal(StoreSpecs.compressed_data)
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    Archive::Zip::Codec::Store::Compress.open(delegate) do |c|
      lambda { c.rewind }.must_raise(Errno::EINVAL)
    end
  end
end
