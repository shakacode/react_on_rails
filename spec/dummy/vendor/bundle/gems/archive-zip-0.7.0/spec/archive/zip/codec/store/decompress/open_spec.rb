# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Decompress.open" do
  it "returns a new instance when run without a block" do
    d = Archive::Zip::Codec::Store::Decompress.open(BinaryStringIO.new)
    d.must_be_instance_of(Archive::Zip::Codec::Store::Decompress)
    d.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::Store::Decompress.open(BinaryStringIO.new) do |decompressor|
      decompressor.must_be_instance_of(Archive::Zip::Codec::Store::Decompress)
    end
  end

  it "closes the object after executing a block" do
    d = Archive::Zip::Codec::Store::Decompress.open(BinaryStringIO.new) do |decompressor|
      decompressor
    end
    d.closed?.must_equal(true)
  end
end
