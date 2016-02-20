# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#close" do
  it "closes the stream" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(BinaryStringIO.new)
    e.close
    e.closed?.must_equal(true)
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close(true)

    delegate = MiniTest::Mock.new
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close(false)
  end
end
