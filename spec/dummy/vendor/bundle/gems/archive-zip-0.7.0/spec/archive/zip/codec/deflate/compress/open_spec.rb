# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress.open" do
  it "returns a new instance when run without a block" do
    c = Archive::Zip::Codec::Deflate::Compress.open(
      BinaryStringIO.new, Zlib::DEFAULT_COMPRESSION
    )
    c.must_be_instance_of(Archive::Zip::Codec::Deflate::Compress)
    c.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::Deflate::Compress.open(
      BinaryStringIO.new, Zlib::DEFAULT_COMPRESSION
    ) { |c| c.must_be_instance_of(Archive::Zip::Codec::Deflate::Compress) }
  end

  it "closes the object after executing a block" do
    Archive::Zip::Codec::Deflate::Compress.open(
      BinaryStringIO.new, Zlib::DEFAULT_COMPRESSION
    ) { |c| c }.closed?.must_equal(true)
  end

  it "allows level to be set" do
    data = DeflateSpecs.test_data
    compressed_data = BinaryStringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) { |c| c.write(data) }

    compressed_data.string.must_equal(DeflateSpecs.compressed_data)

    data = DeflateSpecs.test_data
    compressed_data = BinaryStringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::NO_COMPRESSION
    ) { |c| c.write(data) }

    compressed_data.string.must_equal(DeflateSpecs.compressed_data_nocomp)
  end
end
