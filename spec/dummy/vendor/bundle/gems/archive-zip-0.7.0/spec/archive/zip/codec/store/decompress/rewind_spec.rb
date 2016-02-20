# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.read(4)
        d.rewind
        d.read.must_equal(StoreSpecs.test_data)
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    Archive::Zip::Codec::Store::Decompress.open(delegate) do |d|
      lambda { d.rewind }.must_raise(Errno::EINVAL)
    end
  end
end
