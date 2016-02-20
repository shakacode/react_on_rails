# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt.new" do
  it "returns a new instance" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Encrypt)
    e.close
  end
end
