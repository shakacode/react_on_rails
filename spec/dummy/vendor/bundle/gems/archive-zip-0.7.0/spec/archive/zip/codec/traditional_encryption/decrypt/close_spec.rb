# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#close" do
  it "closes the stream" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close
    d.closed?.must_equal(true)
  end

  it "closes the delegate stream by default" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, "\000" * 12, [Integer])
    delegate.expect(:close, nil)
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = MiniTest::Mock.new
    delegate.expect(:read, "\000" * 12, [Integer])
    delegate.expect(:close, nil)
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close(true)

    delegate = MiniTest::Mock.new
    delegate.expect(:read, "\000" * 12, [Integer])
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close(false)
  end
end
