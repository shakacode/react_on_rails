# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt.open" do
  it "returns a new instance when run without a block" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Decrypt)
    d.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |decryptor|
      decryptor.must_be_instance_of(
        Archive::Zip::Codec::TraditionalEncryption::Decrypt
      )
    end
  end

  it "closes the object after executing a block" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |decryptor|
      decryptor
    end
    d.closed?.must_equal(true)
  end
end
