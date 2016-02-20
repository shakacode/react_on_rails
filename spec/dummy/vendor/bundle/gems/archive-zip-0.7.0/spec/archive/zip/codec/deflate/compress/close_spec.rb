# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#close" do
  it "closes the stream" do
    c = Archive::Zip::Codec::Deflate::Compress.new(
      BinaryStringIO.new, Zlib::DEFAULT_COMPRESSION
    )
    c.close
    c.closed?.must_equal true
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    delegate.expect(:close, nil)
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    delegate.expect(:close, nil)
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close(true)

    delegate = MiniTest::Mock.new
    delegate.expect(:write, 8, [String])
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close(false)
  end
end
