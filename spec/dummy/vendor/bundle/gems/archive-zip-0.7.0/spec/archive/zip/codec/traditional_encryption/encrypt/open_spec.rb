# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt.open" do
  it "returns a new instance when run without a block" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Encrypt)
    e.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |encryptor|
      encryptor.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Encrypt)
    end
  end

  it "closes the object after executing a block" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |encryptor|
      encryptor
    end
    e.closed?.must_equal(true)
  end
end
