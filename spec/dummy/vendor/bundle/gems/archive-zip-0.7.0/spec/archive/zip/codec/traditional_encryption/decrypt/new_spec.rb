# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Decrypt)
    d.close
  end
end
