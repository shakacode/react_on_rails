# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#close" do
  it "closes the stream" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close
    e.closed?.must_equal(true)
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 12, [String])
    delegate.expect(:close, nil)
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 12, [String])
    delegate.expect(:close, nil)
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close(true)

    delegate = MiniTest::Mock.new
    delegate.expect(:write, 12, [String])
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close(false)
  end
end
