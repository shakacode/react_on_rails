# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      e.rewind
      e.write(NullEncryptionSpecs.test_data)
    end
    encrypted_data.string.must_equal(NullEncryptionSpecs.encrypted_data)
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = MiniTest::Mock.new
    delegate.expect(:close, nil)
    Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) do |e|
      lambda { e.rewind }.must_raise(Errno::EINVAL)
    end
  end
end
