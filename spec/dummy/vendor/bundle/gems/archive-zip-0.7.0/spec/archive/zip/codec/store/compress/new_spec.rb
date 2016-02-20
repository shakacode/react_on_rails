# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress.new" do
  it "returns a new instance" do
    c = Archive::Zip::Codec::Store::Compress.new(BinaryStringIO.new)
    c.must_be_instance_of(Archive::Zip::Codec::Store::Compress)
    c.close
  end
end
