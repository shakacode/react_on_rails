# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#write" do
  it "calls the write method of the delegate" do
    delegate = MiniTest::Mock.new
    delegate.expect(
      :write,
      NullEncryptionSpecs.encrypted_data.size,
      [NullEncryptionSpecs.encrypted_data]
    )
    delegate.expect(:close, nil)
    Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) do |e|
      e.write(NullEncryptionSpecs.test_data)
    end
  end

  it "passes data through unmodified" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write(NullEncryptionSpecs.test_data)
    end
    encrypted_data.string.must_equal(NullEncryptionSpecs.encrypted_data)
  end
end
