# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    sio = BinaryStringIO.new
    Zlib::ZWriter.open(sio) do |zw|
      zw.write('test')
      zw.rewind
      zw.write(ZlibSpecs.test_data)
    end
    sio.string.must_equal ZlibSpecs.compressed_data
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    Zlib::ZWriter.open(delegate) do |zw|
      lambda { zw.rewind }.must_raise Errno::EINVAL
    end
  end
end
