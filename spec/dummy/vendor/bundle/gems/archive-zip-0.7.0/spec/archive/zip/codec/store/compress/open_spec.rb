# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress.open" do
  it "returns a new instance when run without a block" do
    c = Archive::Zip::Codec::Store::Compress.open(BinaryStringIO.new)
    c.must_be_instance_of(Archive::Zip::Codec::Store::Compress)
    c.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::Store::Compress.open(BinaryStringIO.new) do |compressor|
      compressor.must_be_instance_of(Archive::Zip::Codec::Store::Compress)
    end
  end

  it "closes the object after executing a block" do
    c = Archive::Zip::Codec::Store::Compress.open(BinaryStringIO.new) do |compressor|
      compressor
    end
    c.closed?.must_equal(true)
  end
end
