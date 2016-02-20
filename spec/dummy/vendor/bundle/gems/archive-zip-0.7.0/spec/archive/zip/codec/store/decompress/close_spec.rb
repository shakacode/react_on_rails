# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Decompress#close" do
  it "closes the stream" do
    c = Archive::Zip::Codec::Store::Decompress.new(BinaryStringIO.new)
    c.close
    c.closed?.must_equal(true)
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    c = Archive::Zip::Codec::Store::Decompress.new(delegate)
    c.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    c = Archive::Zip::Codec::Store::Decompress.new(delegate)
    c.close(true)

    delegate = MiniTest::Mock.new
    c = Archive::Zip::Codec::Store::Decompress.new(delegate)
    c.close(false)
  end
end
