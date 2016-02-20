# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt.new" do
  it "returns a new instance" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(BinaryStringIO.new)
    e.must_be_instance_of(Archive::Zip::Codec::NullEncryption::Encrypt)
    e.close
  end
end
