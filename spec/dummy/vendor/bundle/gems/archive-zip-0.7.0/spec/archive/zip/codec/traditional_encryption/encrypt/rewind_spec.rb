# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write('test')
      # Ensure repeatable test data is used for encryption header.
      srand(0)
      e.rewind
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.must_equal(TraditionalEncryptionSpecs.encrypted_data)
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:write, 12, [String])
    delegate.expect(:close, nil)
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      lambda { e.rewind }.must_raise(Errno::EINVAL)
    end
  end
end
