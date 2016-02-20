# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#close" do
  it "closes the stream" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(BinaryStringIO.new)
    d.close
    d.closed?.must_equal(true)
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close(true)

    delegate = MiniTest::Mock.new
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close(false)
  end
end
