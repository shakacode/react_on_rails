# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(BinaryStringIO.new)
    d.must_be_instance_of(Archive::Zip::Codec::NullEncryption::Decrypt)
    d.close
  end
end
