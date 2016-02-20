# encoding: UTF-8

require 'minitest/autorun'

require File.expand_path('../../fixtures/classes', __FILE__)

require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#crc32" do
  it "computes the CRC32 checksum" do
    compressed_data = BinaryStringIO.new
    closed_compressor = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
      compressor.flush
      compressor.crc32.must_equal Zlib.crc32(DeflateSpecs.test_data)
      compressor
    end
    closed_compressor.crc32.must_equal Zlib.crc32(DeflateSpecs.test_data)
  end
end
