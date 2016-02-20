# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress.new" do
  it "returns a new instance" do
    c = Archive::Zip::Codec::Deflate::Compress.new(
      BinaryStringIO.new, Zlib::DEFAULT_COMPRESSION
    )
    c.must_be_instance_of(Archive::Zip::Codec::Deflate::Compress)
    c.close
  end

  it "allows level to be set" do
    data = DeflateSpecs.test_data
    compressed_data = BinaryStringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.new(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    )
    c.write(data)
    c.close

    compressed_data.string.must_equal(DeflateSpecs.compressed_data)

    compressed_data = BinaryStringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.new(
      compressed_data, Zlib::NO_COMPRESSION
    )
    c.write(data)
    c.close

    compressed_data.string.must_equal(DeflateSpecs.compressed_data_nocomp)
  end
end
